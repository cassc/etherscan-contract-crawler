// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IMembershipsMetadataRegistry {
    function baseTokenURI(address) external view returns (string memory);

    function setBaseTokenURI(address _membershipsProxy, string calldata _baseTokenURI) external;
}