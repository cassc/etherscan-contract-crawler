// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPlayerCardNFT {
     function mintTo(address to, uint256 quantity) external payable;
}