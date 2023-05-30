// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "../solvers/AttractorSolution.sol";

/**
 * @notice Renders a solution of an attractor simulation as SVG
 * @author David Huber (@cxkoda)
 */
interface ISvgRenderer {
    /**
     * @notice Renders a list of 2D points and tangents as svg
     * @param solution List of 16-bit fixed-point points and tangents. 
     * See `AttractorSolution`.
     * @param colormap 256 8-bit RGB colors. Leaving this in memory for easier
     * access in assembly later.
     * @param markerSize A modifier for marker sizes (e.g. stroke width, 
     * point size)
     * @return The generated svg string. The viewport covers the area 
     * [-64, 64] x [-64, 64] by convention.
     */
    function render(
        AttractorSolution calldata solution,
        bytes memory colormap,
        uint8 markerSize
    ) external pure returns (string memory);
}