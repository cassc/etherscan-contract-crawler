/******************************************************************************************************
Staked Yieldification (sYDF)

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import './YDFStake.sol';

contract sYDF is YDFStake {
  constructor(
    address _ydf,
    address _vester,
    address _rewards,
    string memory _baseTokenURI
  )
    YDFStake(
      'Staked Yieldification',
      'sYDF',
      _ydf,
      _ydf,
      _vester,
      _rewards,
      _baseTokenURI
    )
  {
    _addAprLockOption(2500, 0);
    _addAprLockOption(5000, 14 days);
    _addAprLockOption(10000, 120 days);
    _addAprLockOption(15000, 240 days);
    _addAprLockOption(20000, 360 days);
  }
}