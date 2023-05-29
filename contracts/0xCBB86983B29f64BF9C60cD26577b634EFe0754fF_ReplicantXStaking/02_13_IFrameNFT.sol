// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This is an interface for FrameNFTs that will need to be implemented and referenced in the staking contract

interface IFrameNFT {
    function mint(address to) external;

    function nextTokenId() external view returns (uint256);
}