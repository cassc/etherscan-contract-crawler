// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface INFTOperator {
    function safeTransfer(address collection, uint256 tokenId, address receiver) external;

    function burn(address collection, uint256 tokenId) external;
}