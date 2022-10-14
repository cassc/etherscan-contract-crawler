// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITemplate {
    function NAME() external view returns (string memory);

    function VERSION() external view returns (uint256);
}