// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './HLP.sol';
import './LendingPool.sol';

contract LendingPoolExtLP is LendingPool {
  uint32 public externalLpFeePerc = (DENOMENATOR * 75) / 100;
  HLP public hlp;

  constructor(
    string memory _baseTokenURI,
    ISwapRouter __swapRouter,
    IHyperbolicProtocol __hype,
    ITwapUtils __twapUtils,
    LendingRewards __lendingRewards,
    address __WETH
  )
    LendingPool(
      _baseTokenURI,
      __swapRouter,
      __hype,
      __twapUtils,
      __lendingRewards,
      __WETH
    )
  {
    hlp = new HLP();
  }

  function deposit() external payable {
    require(msg.value > 0, 'DEPOSIT: no ETH');
    hlp.mint(_msgSender(), msg.value);
  }

  function withdraw(uint256 _amount) external {
    hlp.burn(_msgSender(), _amount);
    (bool _sent, ) = payable(_msgSender()).call{ value: _amount }('');
    require(_sent, 'WITHDRAW: ETH not sent');
  }

  function _depositRewards(uint256 _amount) internal override {
    uint256 _externalLpRewards = (_amount * externalLpFeePerc) / DENOMENATOR;
    uint256 _hypeHolderRewards = _amount - _externalLpRewards;
    if (_externalLpRewards > 0) {
      LendingRewards _lpRewards = hlp.lendingRewards();
      _lpRewards.depositRewards{ value: _externalLpRewards }();
    }
    if (_hypeHolderRewards > 0) {
      _lendingRewards.depositRewards{ value: _hypeHolderRewards }();
    }
  }

  function setExternalLpFeePerc(uint32 _perc) external onlyOwner {
    require(_perc <= DENOMENATOR, 'lte 100%');
    externalLpFeePerc = _perc;
  }
}