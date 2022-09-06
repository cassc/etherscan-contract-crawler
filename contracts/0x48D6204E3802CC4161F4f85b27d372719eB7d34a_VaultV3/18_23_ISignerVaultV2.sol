// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./ISignerVaultV1.sol";

interface ISignerVaultV2 is ISignerVaultV1 {
  function signersLength() external view returns (uint);
  function signer(uint index) external view returns (address);

  function lockMapIds() external view returns (address[] memory);
  function lockMapIdsLength() external view returns (uint);
  function lockMapId(uint index) external view returns (address);
}