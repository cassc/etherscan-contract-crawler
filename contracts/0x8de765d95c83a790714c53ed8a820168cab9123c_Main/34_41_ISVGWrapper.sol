// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.19;

interface ISVGWrapper {
    struct Size {
        uint256 width;
        uint256 height;
    }

    function getWrappedImage(
        bytes memory imageUri,
        Size memory size
    ) external view returns (bytes memory imageDataUri);
}