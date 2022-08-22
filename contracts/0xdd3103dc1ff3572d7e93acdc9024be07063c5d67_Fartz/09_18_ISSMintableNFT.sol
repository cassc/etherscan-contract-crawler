// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISSMintableNFT {
    function permissionedMint(address receiver_) external;
}