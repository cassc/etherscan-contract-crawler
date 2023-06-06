// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VoteStatusConsumer {
  enum VoteStatus {
    Pending,
    Approved,
    Executed,
    Rejected,
    Expired
  }
}