// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobFundableCredits.sol';
import './Keep3rJobFundableLiquidity.sol';
import '../Keep3rDisputable.sol';

abstract contract Keep3rJobDisputable is IKeep3rJobDisputable, Keep3rDisputable, Keep3rJobFundableCredits, Keep3rJobFundableLiquidity {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @inheritdoc IKeep3rJobDisputable
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external override onlySlasher {
    if (!disputes[_job]) revert NotDisputed();
    if (!_jobTokens[_job].contains(_token)) revert JobTokenUnexistent();
    if (jobTokenCredits[_job][_token] < _amount) revert JobTokenInsufficient();

    try IERC20(_token).transfer(governance, _amount) {} catch {}
    jobTokenCredits[_job][_token] -= _amount;
    if (jobTokenCredits[_job][_token] == 0) {
      _jobTokens[_job].remove(_token);
    }

    emit JobSlashToken(_job, _token, msg.sender, _amount);
  }

  /// @inheritdoc IKeep3rJobDisputable
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external override onlySlasher {
    if (!disputes[_job]) revert NotDisputed();

    _unbondLiquidityFromJob(_job, _liquidity, _amount);
    try IERC20(_liquidity).transfer(governance, _amount) {} catch {}
    emit JobSlashLiquidity(_job, _liquidity, msg.sender, _amount);
  }
}