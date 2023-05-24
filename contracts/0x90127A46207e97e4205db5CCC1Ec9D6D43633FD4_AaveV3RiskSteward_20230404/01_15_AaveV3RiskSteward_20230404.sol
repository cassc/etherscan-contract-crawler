// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IACLManager} from 'aave-address-book/AaveV3.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';

/**
 * @title AaveV3RiskSteward
 * @author BGD labs
 * @notice Contract transfering permissions to the steward
 */
contract AaveV3RiskSteward_20230404 is IProposalGenericExecutor {
  IACLManager public immutable ACL_MANAGER;
  address public immutable STEWARD;

  constructor(IACLManager aclManager, address steward) {
    ACL_MANAGER = aclManager;
    STEWARD = steward;
  }

  function execute() external override {
    ACL_MANAGER.addRiskAdmin(STEWARD);
  }
}