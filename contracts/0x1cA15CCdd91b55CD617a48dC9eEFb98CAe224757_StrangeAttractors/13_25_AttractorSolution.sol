// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

/**
 * @notice The data struct that will be passed from the solver to the renderer.
 * @dev `points` and `tangents` both contain pairs of 16-bit fixed-point numbers
 * with a PRECISION of 6 in row-major order.`dt` is given in the fixed-point
 * respresentation used by the solvers and corresponds to the time step between 
 * the datapoints.
 */
struct AttractorSolution {
    bytes points;
    bytes tangents;
    uint256 dt;
}