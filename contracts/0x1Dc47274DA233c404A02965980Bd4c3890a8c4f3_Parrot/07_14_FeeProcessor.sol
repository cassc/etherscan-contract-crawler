// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract FeeProcessor is Ownable {
  address public developmentWallet;
  address public treasuryWallet;
  address public liquidityWallet;

  address public PRT;
  address public USDC;
  IUniswapV2Router02 public uniswapV2Router;

  modifier onlyPrt() {
    require(msg.sender == PRT, 'only PRT contract can call');
    _;
  }

  constructor(
    address _prt,
    address _usdc,
    address _dexRouter
  ) {
    PRT = _prt;
    USDC = _usdc;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_dexRouter);
    uniswapV2Router = _uniswapV2Router;
  }

  function processAndDistribute(
    uint256 _tokensForDevelopment,
    uint256 _tokensForTreasury,
    uint256 _liquidityPRT
  ) external onlyPrt {
    uint256 _finalSwapAmount = _tokensForDevelopment +
      _tokensForTreasury +
      _liquidityPRT;
    uint256 _usdcBalToProcess = IERC20(USDC).balanceOf(address(this));
    if (_usdcBalToProcess > 0) {
      uint256 _treasuryUSDC = (_usdcBalToProcess * _tokensForTreasury) /
        _finalSwapAmount;
      uint256 _developmentUSDC = (_usdcBalToProcess * _tokensForDevelopment) /
        _finalSwapAmount;
      uint256 _liquidityUSDC = _usdcBalToProcess -
        _treasuryUSDC -
        _developmentUSDC;
      _processFees(
        _developmentUSDC,
        _treasuryUSDC,
        _liquidityUSDC,
        _liquidityPRT
      );
    }
  }

  function _processFees(
    uint256 _developmentUSDC,
    uint256 _treasuryUSDC,
    uint256 _liquidityUSDC,
    uint256 _liquidityPRT
  ) internal {
    IERC20 _usdc = IERC20(USDC);
    if (_developmentUSDC > 0) {
      address _developmentWallet = developmentWallet == address(0)
        ? owner()
        : developmentWallet;
      _usdc.transfer(_developmentWallet, _developmentUSDC);
    }

    if (_treasuryUSDC > 0) {
      address _treasuryWallet = treasuryWallet == address(0)
        ? owner()
        : treasuryWallet;
      _usdc.transfer(_treasuryWallet, _treasuryUSDC);
    }

    if (_liquidityUSDC > 0 && _liquidityPRT > 0) {
      _addLp(_liquidityPRT, _liquidityUSDC);
    }
  }

  function _addLp(uint256 prtAmount, uint256 usdcAmount) internal {
    address _liquidityWallet = liquidityWallet == address(0)
      ? owner()
      : liquidityWallet;
    IERC20 _prt = IERC20(PRT);
    IERC20 _usdc = IERC20(USDC);

    _prt.approve(address(uniswapV2Router), prtAmount);
    _usdc.approve(address(uniswapV2Router), usdcAmount);
    uniswapV2Router.addLiquidity(
      USDC,
      PRT,
      usdcAmount,
      prtAmount,
      0,
      0,
      _liquidityWallet,
      block.timestamp
    );
    uint256 _contUSDCBal = _usdc.balanceOf(address(this));
    if (_contUSDCBal > 0) {
      _usdc.transfer(_liquidityWallet, _contUSDCBal);
    }
    uint256 _contPRTBal = _prt.balanceOf(address(this));
    if (_contPRTBal > 0) {
      _prt.transfer(_liquidityWallet, _contPRTBal);
    }
  }

  function setDevelopmentWallet(address _wallet) external onlyOwner {
    developmentWallet = _wallet;
  }

  function setTreasuryWallet(address _wallet) external onlyOwner {
    treasuryWallet = _wallet;
  }

  function setLiquidityWallet(address _wallet) external onlyOwner {
    liquidityWallet = _wallet;
  }
}