// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFrameGenerator {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }

    function generateFrame(uint16 Frame)
        external
        view
        returns (FrameData memory);
}