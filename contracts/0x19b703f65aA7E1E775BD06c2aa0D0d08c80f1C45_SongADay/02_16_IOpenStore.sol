// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


// @title Interface for OpenSea Shared Storefront (OPENSTORE) contract.
interface IOpenStore {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}