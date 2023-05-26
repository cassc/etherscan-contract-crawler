// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHypebItems {
    function create(uint256, string calldata) external returns(uint256);
    function mintItem(uint256, address, uint256) external;
    function setURI(string calldata, uint256) external;
}