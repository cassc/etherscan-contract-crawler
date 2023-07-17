// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './interfaces/IERC20.sol';
import {VersionedInitializable} from './libs/VersionedInitializable.sol';
import {SafeERC20} from './libs/SafeERC20.sol';

/**
 * @title AaveIncentivesVault
 * @notice Stores all the AAVE kept for incentives, just giving approval to the different
 * systems that will pull AAVE funds for their specific use case
 * @author Aave
 **/
contract AaveIncentivesVault is VersionedInitializable {
  using SafeERC20 for IERC20;

  uint256 public constant REVISION = 1;

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal override pure returns (uint256) {
    return REVISION;
  }

  /**
   * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
   * On this first revision:
   * - Approves the StakedAave contract to pull AAVE funds to distribute as incentives
   * @param aave Address of the AAVE token
   * @param stakedAave Address of the stkAAVE token (AAVE staking contract)
   * @param initialStakingDistribution Amount of AAVE to approve to the stkAAVE contract
   */
  function initialize(
    IERC20 aave,
    address stakedAave,
    uint256 initialStakingDistribution
  ) external initializer {
    aave.safeApprove(stakedAave, initialStakingDistribution);
  }
}