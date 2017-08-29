#!python
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Cython "wrapped" interface for `_curve_helpers`."""


import numpy as np
from numpy cimport ndarray as ndarray_t

cimport bezier._curve


def evaluate_multi_barycentric(
        double[::1, :] nodes, double[:] lambda1, double[:] lambda2):
    cdef int num_nodes, dimension, degree, num_vals
    cdef ndarray_t[double, ndim=2, mode='fortran'] evaluated

    num_nodes, dimension = np.shape(nodes)
    degree = num_nodes - 1
    num_vals, = np.shape(lambda1)
    evaluated = np.empty((num_vals, dimension), order='F')
    bezier._curve.evaluate_curve_barycentric(
        &degree,
        &dimension,
        &nodes[0, 0],
        &num_vals,
        &lambda1[0],
        &lambda2[0],
        &evaluated[0, 0],
    )
    return evaluated


def evaluate_multi(
        double[::1, :] nodes, double[:] s_vals):
    cdef int num_nodes, dimension, degree, num_vals
    cdef ndarray_t[double, ndim=2, mode='fortran'] evaluated

    num_nodes, dimension = np.shape(nodes)
    degree = num_nodes - 1
    num_vals, = np.shape(s_vals)
    evaluated = np.empty((num_vals, dimension), order='F')
    bezier._curve.evaluate_multi(
        &degree,
        &dimension,
        &nodes[0, 0],
        &num_vals,
        &s_vals[0],
        &evaluated[0, 0],
    )
    return evaluated


def specialize_curve(
        double[::1, :] nodes, double start, double end,
        double curve_start, double curve_end, int degree):
    cdef int num_nodes, dimension
    cdef double true_start, true_end
    cdef ndarray_t[double, ndim=2, mode='fortran'] new_nodes

    num_nodes, dimension = np.shape(nodes)
    new_nodes = np.empty((num_nodes, dimension), order='F')

    bezier._curve.specialize_curve(
        &degree,
        &dimension,
        &nodes[0, 0],
        &start,
        &end,
        &curve_start,
        &curve_end,
        &new_nodes[0, 0],
        &true_start,
        &true_end,
    )

    return new_nodes, true_start, true_end


def evaluate_hodograph(double s, double[::1, :] nodes, int degree):
    cdef int dimension
    cdef ndarray_t[double, ndim=2, mode='fortran'] hodograph

    # NOTE: We don't check that there are ``degree + 1`` rows.
    _, dimension = np.shape(nodes)

    hodograph = np.empty((1, dimension), order='F')

    bezier._curve.evaluate_hodograph(
        &s,
        &nodes[0, 0],
        &dimension,
        &degree,
        &hodograph[0, 0],
    )

    return hodograph
