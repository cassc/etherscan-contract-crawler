// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

  /** 1 Royalty Receiver */
  struct RoyaltyReceiver {
    /** Address to receive royalties */
    address receiver;
    /** Percentage share to receive */
    uint256 share;
  }