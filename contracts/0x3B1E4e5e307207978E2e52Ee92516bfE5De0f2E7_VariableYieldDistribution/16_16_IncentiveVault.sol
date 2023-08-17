// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {GeneralVault} from './GeneralVault.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {VariableYieldDistribution} from '../../incentives/VariableYieldDistribution.sol';

/**
 * @title IncentiveVault
 * @notice Basic incentive feature of vault
 * @author Sturdy
 **/

abstract contract IncentiveVault is GeneralVault {
  using SafeERC20 for IERC20;

  /**
   * @dev Emitted on setIncentiveRatio()
   * @param ratio The incentive ratio value, 1% = 100
   **/
  event SetIncentiveRatio(uint256 ratio);

  /**
   * @dev Get the incentive token address supported on this vault
   * @return The address of incentive token
   */
  function getIncentiveToken() public view virtual returns (address);

  /**
   * @dev Get current total incentive amount
   * @return The total amount of incentive token
   */
  function getCurrentTotalIncentiveAmount() external view virtual returns (uint256);

  /**
   * @dev Get Incentive Ratio
   * @return The incentive ratio value
   */
  function getIncentiveRatio() external view virtual returns (uint256);

  /**
   * @dev Set Incentive Ratio
   * - Caller is only PoolAdmin which is set on LendingPoolAddressesProvider contract
   */
  function setIncentiveRatio(uint256 _ratio) external virtual;

  /**
   * @dev Get AToken address for the vault
   * @return The AToken address for the vault
   */
  function _getAToken() internal view virtual returns (address);

  /**
   * @dev Claim all rewards and send some to YieldDistributor
   */
  function _clearRewards() internal virtual;

  /**
   * @dev Send incentive to YieldDistribution
   * @param amount The amount of incentive token
   */
  function _sendIncentive(uint256 amount) internal {
    address asset = _getAToken();
    address incentiveToken = getIncentiveToken();

    // transfer to YieldDistributor
    address yieldDistributor = _addressesProvider.getAddress('VR_YIELD_DISTRIBUTOR');
    IERC20(incentiveToken).safeTransfer(yieldDistributor, amount);

    // notify to YieldDistributor so that it updates asset index
    VariableYieldDistribution(yieldDistributor).receivedRewards(asset, incentiveToken, amount);
  }
}