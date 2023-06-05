// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface GmDataInterface {
    struct GmDataSet {
        bytes imageName;
        bytes compressedImage;
        uint256 compressedSize;
    }

    function getSvg(uint256 index) external pure returns (GmDataSet memory);
}