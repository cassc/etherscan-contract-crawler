// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";

interface IContractDeployerV1 is IVersion {
  function router() external view returns (address);
  function feeSetter() external view returns (address);

  function addressOf(string memory identifier_, uint version_) external view returns (address);
  function deploy(string memory identifier_, uint version_, bytes memory bytecode) external;
  function initialize(string memory identifier_, uint version_) external;
}