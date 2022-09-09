// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAvatar {
    function batchMint(address to, uint256 startTokenId, uint256 amount) external;
}