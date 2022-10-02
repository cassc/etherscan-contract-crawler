// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IPublicMintable {
    function publicMint(uint256 editionId, uint24 quantity) external payable;
}