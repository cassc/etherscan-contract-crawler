// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PausableStorage {
  bool paused;
  uint64 pausedAt;
}