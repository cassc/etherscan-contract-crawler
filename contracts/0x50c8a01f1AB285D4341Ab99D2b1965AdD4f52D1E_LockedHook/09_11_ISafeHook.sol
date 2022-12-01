// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface ISafeHook {
    function executeHook(address from, address to, uint256 tokenId) external returns(bool success);
}