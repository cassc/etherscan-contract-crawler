// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVaultV1.sol";
import "../enums/CurrencyType.sol";
import "../structs/MultiVaultsClaimsAndUnlocksOperation.sol";
import "../structs/MultiVaultsLockMapsOperation.sol";
import "../structs/MultiVaultsLocksOperation.sol";

interface IVaultV2 is IVaultV1 {
  function voteInitiator(address vault) external view returns (address);

  function lockMapMultiple(MultiVaultsLockMapsOperation[] calldata operations) external view returns (LockMap[][] memory);
  function claimMultiple(MultiVaultsClaimsAndUnlocksOperation[] calldata operations) external;
  function unlockMultiple(MultiVaultsClaimsAndUnlocksOperation[] calldata operations) external;
  function lockMultiple(MultiVaultsLocksOperation[] calldata operations) external payable;
  function lockMultipleOnPartner(MultiVaultsLocksOperation[] calldata operations, address partner) external payable;
}