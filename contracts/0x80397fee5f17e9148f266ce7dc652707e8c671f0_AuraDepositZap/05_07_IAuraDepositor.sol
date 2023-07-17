// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

interface IAuraDepositor {
    function depositFor(address to, uint256 _amount) external;
}