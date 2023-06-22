// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPublicMintable {
    function mintPublic(address to, uint256 n) external payable;
}