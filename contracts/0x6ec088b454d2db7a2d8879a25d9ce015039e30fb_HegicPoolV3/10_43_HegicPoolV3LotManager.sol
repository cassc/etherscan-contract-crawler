// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../../interfaces/HegicPool/V3/IHegicPoolV3LotManager.sol';

import './HegicPoolV3ProtocolParameters.sol';

abstract
contract HegicPoolV3LotManager is HegicPoolV3ProtocolParameters, IHegicPoolV3LotManager {

  using SafeERC20 for IERC20;

  function _claimRewards() internal returns (uint _rewards) {
    _rewards = lotManager.claimRewards();
    emit RewardsClaimed(_rewards);
  }

  function _buyLots(uint256 _eth, uint256 _wbtc) internal returns (bool) {
    uint _totalLots = _eth.add(_wbtc);
    require(unusedUnderlyingBalance() >= minTokenReserves.add(_totalLots.mul(lotManager.lotPrice())), 'HegicPoolV3LotManager::_buyLots::not-enough-reserves');
    // Gets available underlying. unused - reserves
    uint256 availableUnderlying = unusedUnderlyingBalance().sub(minTokenReserves);
    // Check and approve underlyingBalace to LotManager
    token.approve(address(lotManager), availableUnderlying);
    // Calls LotManager to buyLots
    require(lotManager.buyLots(_eth, _wbtc), 'HegicPoolV3LotManager::_buyLots::error-while-buying-lots');
    emit LotsBought(_eth, _wbtc);
    return true;
  }
}