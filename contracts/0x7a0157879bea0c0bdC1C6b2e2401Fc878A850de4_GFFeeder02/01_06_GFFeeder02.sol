// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeToken.sol";
import "./base/BaseFeeder.sol";

contract GFFeeder02 is BaseFeeder {
  using SafeToken for address;

  constructor(
    address _rewardManager,
    address _rewardSource,
    uint256 _rewardRatePerBlock,
    uint40 _lastRewardBlock,
    uint40 _rewardEndBlock
  ) BaseFeeder( _rewardManager, _rewardSource, _rewardRatePerBlock, _lastRewardBlock, _rewardEndBlock) {
    token.safeApprove(_rewardManager, type(uint256).max);
  }

  function _feed() override internal  {
    uint40 _rewardEndBlock = rewardEndBlock;
    uint256 _lastRewardBlock = lastRewardBlock;
    uint256 blockDelta = _getMultiplier(_lastRewardBlock, block.number, _rewardEndBlock);
    if (blockDelta == 0) {
      return;
    }

    uint256 _toDistribute = rewardRatePerBlock * blockDelta;
    uint40 blockNumber = uint40(block.number);
    lastRewardBlock = blockNumber > _rewardEndBlock ? _rewardEndBlock : blockNumber;
    if (_toDistribute > 0) {
      token.safeTransferFrom(rewardSource, address(this), _toDistribute);
      rewardManager.feed(_toDistribute);
    }

    emit Feed(_toDistribute);
  }


  function _getMultiplier(
    uint256 _from,
    uint256 _to,
    uint256 _endBlock
  ) internal pure returns (uint256) {
    if ((_from >= _endBlock) || (_from > _to)) {
      return 0;
    }

    if (_to <= _endBlock) {
      return _to - _from;
    }
    return _endBlock - _from;
  }
}