// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IProvider {
    function url() external view returns (string memory);
    function isKnown(address _wallet) external view returns (bool);
}