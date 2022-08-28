// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./Fees.sol";

struct Collaborations {
  uint length;
  address[] addresses;
  uint[] minBalances;
  Fees[] reductions;
}