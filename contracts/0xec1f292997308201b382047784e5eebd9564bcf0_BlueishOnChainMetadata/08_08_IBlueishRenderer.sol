// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBlueishRenderer {
    function render(uint256 id) external view returns (string memory);
}