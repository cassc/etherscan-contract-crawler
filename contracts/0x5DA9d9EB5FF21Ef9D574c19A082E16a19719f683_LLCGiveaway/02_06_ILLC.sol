// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILLC {
    function mint(address, uint256) external;

    function totalSupply() external view returns (uint256);

    function tokenCount() external view returns (uint256);
}