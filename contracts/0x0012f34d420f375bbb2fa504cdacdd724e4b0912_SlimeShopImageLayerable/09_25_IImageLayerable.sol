// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IImageLayerable {
    function setBaseLayerURI(string calldata baseLayerURI) external;

    function setDefaultURI(string calldata baseLayerURI) external;

    function getDefaultImageURI(uint256 layerId)
        external
        returns (string memory);
}