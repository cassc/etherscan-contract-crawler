// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function contractURI() external view returns (string memory);

    function initializeWithData(bytes memory initData) external;
}