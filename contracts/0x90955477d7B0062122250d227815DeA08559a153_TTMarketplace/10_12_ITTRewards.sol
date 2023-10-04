// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITTRewards {
    function receiveRewards(uint256 amount, uint256 tokenId) external;
}