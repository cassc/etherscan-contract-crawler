// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./StrategyFarmLPBabyDoge.sol";


contract StrategyEndedLPBabyDoge is StrategyFarmLPBabyDoge {

  constructor(
    address _unirouter,
    address _want,
    address _output,
    address _native,

    address _callFeeRecipient,
    address _frfiFeeRecipient,
    address _strategistFeeRecipient,

    address _safeFarmFeeRecipient,

    address _treasuryFeeRecipient,
    address _systemFeeRecipient
  ) StrategyFarmLPBabyDoge(
    _unirouter,
    _want,
    _output,
    _native,

    _callFeeRecipient,
    _frfiFeeRecipient,
    _strategistFeeRecipient,

    _safeFarmFeeRecipient,

    _treasuryFeeRecipient,
    _systemFeeRecipient
  ) {
  }

// INTERNAL FUNCTIONS

  function _poolDeposit(uint256 _amount) internal override virtual {
    // skip farm methods
  }

  function _poolWithdraw(uint256 _amount) internal override virtual {
    // skip farm methods
  }
}