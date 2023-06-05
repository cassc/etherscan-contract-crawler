// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TokenHelper} from '../libraries/TokenHelper.sol';

import {IRouterTokenHelperWithFee} from '../../interfaces/periphery/IRouterTokenHelperWithFee.sol';
import {IWETH} from '../../interfaces/IWETH.sol';

import {RouterTokenHelper} from './RouterTokenHelper.sol';

abstract contract RouterTokenHelperWithFee is RouterTokenHelper, IRouterTokenHelperWithFee {
  uint256 constant FEE_UNITS = 100000;

  constructor(address _factory, address _WETH) RouterTokenHelper(_factory, _WETH) {}

  function unwrapWethWithFee(
    uint256 minAmount,
    address recipient,
    uint256 feeUnits,
    address feeRecipient
  ) public payable override {
    require(feeUnits > 0 && feeUnits <= 1000, 'High fee');

    uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
    require(balanceWETH >= minAmount, 'Insufficient WETH');

    if (balanceWETH > 0) {
      IWETH(WETH).withdraw(balanceWETH);
      uint256 feeAmount = (balanceWETH * feeUnits) / FEE_UNITS;
      if (feeAmount > 0) TokenHelper.transferEth(feeRecipient, feeAmount);
      TokenHelper.transferEth(recipient, balanceWETH - feeAmount);
    }
  }

  function transferAllTokensWithFee(
    address token,
    uint256 minAmount,
    address recipient,
    uint256 feeUnits,
    address feeRecipient
  ) public payable override {
    require(feeUnits > 0 && feeUnits <= 1000, 'High fee');

    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= minAmount, 'Insufficient token');

    if (balanceToken > 0) {
      uint256 feeAmount = (balanceToken * feeUnits) / FEE_UNITS;
      if (feeAmount > 0)
        TokenHelper.transferToken(IERC20(token), feeAmount, address(this), feeRecipient);
      TokenHelper.transferToken(IERC20(token), balanceToken - feeAmount, address(this), recipient);
    }
  }
}