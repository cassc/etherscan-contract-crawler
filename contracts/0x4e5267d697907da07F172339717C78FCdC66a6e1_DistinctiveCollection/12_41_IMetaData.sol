// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetaData {
    function updateBaseURI(string memory baseURI_) external;

    function baseURI() external view returns (string memory uri);
}