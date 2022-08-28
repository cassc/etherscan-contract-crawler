// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../enums/CurrencyType.sol";

struct MultiVaultsClaimsAndUnlocksOperation {
  address vault;
  CurrencyType[] currencyTypes;
  address[] ids;
  uint[] values;
  address recipient;
}