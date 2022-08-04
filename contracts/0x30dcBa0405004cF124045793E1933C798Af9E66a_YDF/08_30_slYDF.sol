/******************************************************************************************************
Staked Yieldification Liquidity (slYDF)

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './YDFStake.sol';

contract slYDF is YDFStake {
  address private _uniswapRouter;
  uint8 public zapBuySlippage = 2; // 2%
  uint8 public zapSellSlippage = 25; // 25%

  event StakeLiquidity(address indexed user, uint256 amountUniLPStaked);
  event ZapETHOnly(
    address indexed user,
    uint256 amountETH,
    uint256 amountUniLPStaked
  );
  event ZapYDFOnly(
    address indexed user,
    uint256 amountYDF,
    uint256 amountUniLPStaked
  );
  event ZapETHAndYDF(
    address indexed user,
    uint256 amountETH,
    uint256 amountYDF,
    uint256 amountUniLPStaked
  );

  constructor(
    address _pair,
    address _router,
    address _ydf,
    address _vester,
    address _rewards,
    string memory _baseTokenURI
  )
    YDFStake(
      'Staked Yieldification Liquidity',
      'slYDF',
      _pair,
      _ydf,
      _vester,
      _rewards,
      _baseTokenURI
    )
  {
    _uniswapRouter = _router;
    _addAprLockOption(5000, 0);
    _addAprLockOption(7500, 14 days);
    _addAprLockOption(15000, 120 days);
    _addAprLockOption(22500, 240 days);
    _addAprLockOption(30000, 360 days);
  }

  function stake(uint256 _amount, uint256 _lockOptIndex) external override {
    _stakeLp(msg.sender, _amount, _lockOptIndex, true);
    emit StakeLiquidity(msg.sender, _amount);
  }

  function zapAndStakeETHOnly(uint256 _lockOptIndex) external payable {
    require(msg.value > 0, 'need to provide ETH to zap');

    uint256 _ethBalBefore = address(this).balance - msg.value;
    uint256 _ydfBalanceBefore = ydf.balanceOf(address(this));
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);

    // swap half the ETH for YDF
    uint256 _tokensToReceiveNoSlip = _getTokensToReceiveOnBuyNoSlippage(
      msg.value / 2
    );
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = address(ydf);
    _uniswapV2Router.swapExactETHForTokens{ value: msg.value / 2 }(
      (_tokensToReceiveNoSlip * (100 - zapBuySlippage)) / 100, // handle slippage
      path,
      address(this),
      block.timestamp
    );

    uint256 _lpBalBefore = stakeToken.balanceOf(address(this));
    _addLp(ydf.balanceOf(address(this)) - _ydfBalanceBefore, msg.value / 2);
    uint256 _lpBalanceToStake = stakeToken.balanceOf(address(this)) -
      _lpBalBefore;
    _stakeLp(msg.sender, _lpBalanceToStake, _lockOptIndex, false);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalanceBefore);

    emit ZapETHOnly(msg.sender, msg.value, _lpBalanceToStake);
  }

  function zapAndStakeETHAndYDF(uint256 _amountYDF, uint256 _lockOptIndex)
    external
    payable
  {
    require(msg.value > 0, 'need to provide ETH to zap');

    uint256 _ethBalBefore = address(this).balance - msg.value;
    uint256 _ydfBalBefore = ydf.balanceOf(address(this));
    ydf.transferFrom(msg.sender, address(this), _amountYDF);
    uint256 _ydfToProcess = ydf.balanceOf(address(this)) - _ydfBalBefore;

    uint256 _lpBalBefore = stakeToken.balanceOf(address(this));
    _addLp(_ydfToProcess, msg.value);
    uint256 _lpBalanceToStake = stakeToken.balanceOf(address(this)) -
      _lpBalBefore;
    _stakeLp(msg.sender, _lpBalanceToStake, _lockOptIndex, false);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalBefore);

    emit ZapETHAndYDF(msg.sender, msg.value, _amountYDF, _lpBalanceToStake);
  }

  function zapAndStakeYDFOnly(uint256 _amountYDF, uint256 _lockOptIndex)
    external
  {
    require(
      _aprLockOptions[_lockOptIndex].lockTime > 0,
      'cannot zap and stake YDF only without lockup period'
    );
    uint256 _ethBalBefore = address(this).balance;
    uint256 _ydfBalBefore = ydf.balanceOf(address(this));
    ydf.transferFrom(msg.sender, address(this), _amountYDF);
    uint256 _ydfToProcess = ydf.balanceOf(address(this)) - _ydfBalBefore;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);

    // swap half the YDF for ETH
    uint256 _ethToReceiveNoSlip = _getETHToReceiveOnSellNoSlippage(
      _ydfToProcess / 2
    );
    address[] memory path = new address[](2);
    path[0] = address(ydf);
    path[1] = _uniswapV2Router.WETH();
    ydf.approve(address(_uniswapV2Router), _ydfToProcess / 2);
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _ydfToProcess / 2,
      (_ethToReceiveNoSlip * (100 - zapSellSlippage)) / 100, // handle slippage
      path,
      address(this),
      block.timestamp
    );

    uint256 _lpBalBefore = stakeToken.balanceOf(address(this));
    _addLp(_ydfToProcess / 2, address(this).balance - _ethBalBefore);
    uint256 _lpBalanceToStake = stakeToken.balanceOf(address(this)) -
      _lpBalBefore;
    _stakeLp(msg.sender, _lpBalanceToStake, _lockOptIndex, false);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalBefore);

    emit ZapYDFOnly(msg.sender, _amountYDF, _lpBalanceToStake);
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
    ydf.approve(address(_uniswapV2Router), tokenAmount);
    _uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(ydf),
      tokenAmount,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function _getTokensToReceiveOnBuyNoSlippage(uint256 _amountETH)
    internal
    view
    returns (uint256)
  {
    IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
    (uint112 _r0, uint112 _r1, ) = pair.getReserves();
    if (pair.token0() == IUniswapV2Router02(_uniswapRouter).WETH()) {
      return (_amountETH * _r1) / _r0;
    } else {
      return (_amountETH * _r0) / _r1;
    }
  }

  function _getETHToReceiveOnSellNoSlippage(uint256 _amountYDF)
    internal
    view
    returns (uint256)
  {
    IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
    (uint112 _r0, uint112 _r1, ) = pair.getReserves();
    if (pair.token0() == IUniswapV2Router02(_uniswapRouter).WETH()) {
      return (_amountYDF * _r0) / _r1;
    } else {
      return (_amountYDF * _r1) / _r0;
    }
  }

  function _stakeLp(
    address _user,
    uint256 _amountStakeToken,
    uint256 _lockOptIndex,
    bool _transferStakeToken
  ) internal {
    IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
    _amountStakeToken = _amountStakeToken == 0
      ? pair.balanceOf(_user)
      : _amountStakeToken;
    (uint112 res0, uint112 res1, ) = pair.getReserves();
    address t0 = pair.token0();
    uint256 ydfReserves = t0 == address(ydf) ? res0 : res1;
    uint256 singleSideTokenAmount = (_amountStakeToken * ydfReserves) /
      stakeToken.totalSupply();

    // need to multiply the earned amount by 2 since when providing LP
    // the user provides both sides of the pair, so we account for both
    // sides of the pair by multiplying by 2
    _stake(
      _user,
      _amountStakeToken,
      singleSideTokenAmount * 2,
      _lockOptIndex,
      _transferStakeToken
    );
  }

  function _returnExcessETH(address _user, uint256 _initialBal) internal {
    if (address(this).balance > _initialBal) {
      payable(_user).call{ value: address(this).balance - _initialBal }('');
      require(address(this).balance >= _initialBal, 'took too much');
    }
  }

  function _returnExcessYDF(address _user, uint256 _initialBal) internal {
    uint256 _currentBal = ydf.balanceOf(address(this));
    if (_currentBal > _initialBal) {
      ydf.transfer(_user, _currentBal - _initialBal);
      require(ydf.balanceOf(address(this)) >= _initialBal, 'took too much');
    }
  }

  function setZapBuySlippage(uint8 _slippage) external onlyOwner {
    require(_slippage <= 100, 'cannot be more than 100% slippage');
    zapBuySlippage = _slippage;
  }

  function setZapSellSlippage(uint8 _slippage) external onlyOwner {
    require(_slippage <= 100, 'cannot be more than 100% slippage');
    zapSellSlippage = _slippage;
  }

  receive() external payable {}
}