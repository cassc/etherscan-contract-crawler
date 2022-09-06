// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IISeigManager {
    function stakeOf(address layer2, address account)
        external
        view
        returns (uint256);
}