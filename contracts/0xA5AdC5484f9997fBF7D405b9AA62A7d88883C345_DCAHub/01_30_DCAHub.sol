// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import './DCAHubParameters.sol';
import './DCAHubPositionHandler.sol';
import './DCAHubSwapHandler.sol';
import './DCAHubConfigHandler.sol';
import './DCAHubPlatformHandler.sol';

contract DCAHub is DCAHubParameters, DCAHubConfigHandler, DCAHubSwapHandler, DCAHubPositionHandler, DCAHubPlatformHandler, IDCAHub {
  constructor(
    address _immediateGovernor,
    address _timeLockedGovernor,
    ITokenPriceOracle _oracle,
    IDCAPermissionManager _permissionManager
  ) DCAHubPositionHandler(_permissionManager) DCAHubConfigHandler(_immediateGovernor, _timeLockedGovernor, _oracle) {}

  /// @inheritdoc IDCAHubConfigHandler
  function paused() public view override(IDCAHubConfigHandler, DCAHubConfigHandler) returns (bool) {
    return super.paused();
  }
}