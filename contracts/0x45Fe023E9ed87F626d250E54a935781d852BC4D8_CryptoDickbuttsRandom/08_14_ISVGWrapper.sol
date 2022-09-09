// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface ISVGWrapper {
    function getWrappedImage(
        string memory imageUri,
        uint256 canonicalWidth,
        uint256 canonicalHeight
    ) external view returns (string memory imageDataUri);
}