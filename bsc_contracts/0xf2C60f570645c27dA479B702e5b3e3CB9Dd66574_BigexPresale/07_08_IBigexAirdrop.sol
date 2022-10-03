// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBigexAirdrop {
    function getRef(address account) external view returns (address);
}