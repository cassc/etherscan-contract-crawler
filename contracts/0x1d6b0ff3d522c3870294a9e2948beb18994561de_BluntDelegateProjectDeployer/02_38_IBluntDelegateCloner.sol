// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './IBluntDelegateDeployer.sol';

interface IBluntDelegateCloner is IBluntDelegateDeployer {
  function implementation() external returns (address);
}