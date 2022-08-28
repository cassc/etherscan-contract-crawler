// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IFeeCollectorV1.sol";
import "../enums/CurrencyType.sol";

interface IFeeCollectorV2 is IFeeCollectorV1 {
  function payLockFee(CurrencyType currencyType, address vault, address signer) external payable returns (uint);
  function payLockFeeOnPartner(CurrencyType currencyType, address vault, address signer, address partner) external payable returns (uint);

  function paySwapLiquidityFee(address vault, address signer) external payable returns (uint);
  function paySwapLiquidityFeeOnPartner(address vault, address signer, address partner) external payable returns (uint);
}