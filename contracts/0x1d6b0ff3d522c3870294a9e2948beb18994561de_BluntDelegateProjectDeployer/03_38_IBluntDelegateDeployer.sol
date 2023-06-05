// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../structs/DeployBluntDelegateData.sol';
import '../structs/DeployBluntDelegateDeployerData.sol';
import {IJBDelegatesRegistry} from './IJBDelegatesRegistry.sol';

interface IBluntDelegateDeployer {
  event DelegateDeployed(uint256 indexed projectId, address newDelegate);

  function delegatesRegistry() external view returns (IJBDelegatesRegistry);

  function deployDelegateFor(
    DeployBluntDelegateDeployerData memory _deployBluntDelegateDeployerData,
    DeployBluntDelegateData memory _deployBluntDelegateData
  ) external returns (address newDelegate);
}