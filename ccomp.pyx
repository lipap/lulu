import numpy as np
cimport numpy as np
import cython

"""
See also:

  Christophe Fiorio and Jens Gustedt,
  "Two linear time Union-Find strategies for image processing",
  Theoretical Computer Science 154 (1996), pp. 165-181.

  Kensheng Wu, Ekow Otoo and Arie Shoshani,
  "Optimizing connected component labeling algorithms",
  Paper LBNL-56864, 2005,
  Lawrence Berkeley National Laboratory
  (University of California),
  http://repositories.cdlib.org/lbnl/LBNL-56864.

"""

# Tree operations implemented by an array as described in Wu et al.

DTYPE = np.int
ctypedef np.int_t DTYPE_t

cdef DTYPE_t find_root(int *work, int n):
    """Find the root of node n.

    """
    cdef int root = n
    while (work[root] < root):
        root = work[root]
    return root

cdef set_root(int *work, int n, int root):
    """
    Set all nodes on a path to point to new_root.

    """
    cdef int j
    while (work[n] < n):
        j = work[n]
        work[n] = root
        n = j

    work[n] = root


cdef join_trees(int *work, int n, int m):
    """Join two trees containing nodes n and m.

    """
    cdef int root = find_root(work, n)
    cdef int root_m

    if (n != m):
        root_m = find_root(work, m)

        if (root > root_m):
            root = root_m

        set_root(work, n, root)
        set_root(work, m, root)

# Connected components search as described in Fiorio et al.

def label(np.ndarray[DTYPE_t, ndim=2] input):
    """Label connected regions of an integer array.

    """
    cdef int rows = input.shape[0]
    cdef int cols = input.shape[1]

    cdef np.ndarray[DTYPE_t, ndim=2] data = input.copy()
    cdef np.ndarray[DTYPE_t, ndim=2] work

    work = np.arange(data.size, dtype=DTYPE).reshape((rows, cols))

    cdef int *work_p = <int*>work.data
    cdef int *data_p = <int*>data.data

    cdef int i, j

    # Initialize the first row
    for j in range(1, cols):
        if data[0, j] == data[0, j-1]:
            join_trees(work_p, j, j-1)

    for i in range(1, rows):
        # Handle the first column
        if data[i, 0] == data[i-1, 0]:
            join_trees(work_p, i*cols, (i-1)*cols)

        for j in range(1, cols):
            if data[i, j] == data[i-1, j]:
                join_trees(work_p, i*cols + j, (i-1)*cols + j)

            if data[i, j] == data[i, j-1]:
                join_trees(work_p, i*cols + j, i*cols + j - 1)

    # Label output

    cdef int ctr = 0
    for i in range(rows):
        for j in range(cols):
            if (i*cols + j) == work[i, j]:
                data[i, j] = ctr
                ctr = ctr + 1
            else:
                data[i, j] = data_p[work[i, j]]

    return data
