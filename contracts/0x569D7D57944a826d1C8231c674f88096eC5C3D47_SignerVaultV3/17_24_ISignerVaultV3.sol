// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./ISignerVaultV2.sol";
import "../enums/CurrencyType.sol";

interface ISignerVaultV3 is ISignerVaultV2 {
  function voteInitiator() external view returns (address);

  function lockCurrency(CurrencyType currencyType, address id, uint value, uint until) external payable;

  function lockMapMultiple(address[] calldata ids) external view returns (LockMap[] memory);
  function claimMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient) external;
  function unlockMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient) external;
  function unlockMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, address recipient, address voter) external;
  function lockMultiple(CurrencyType[] calldata currencyTypes, address[] calldata ids, uint[] calldata values, uint[] calldata untils) external payable;
}