// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


interface IContentProvider {

    function setContent(string memory name, string memory relativePath, string memory content) external;
    function getContent(string memory name, string memory realtivePath) external view returns (string memory);

}