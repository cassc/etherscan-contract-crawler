// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TokenHelper} from '../libraries/TokenHelper.sol';

import {IRouterTokenHelper} from '../../interfaces/periphery/IRouterTokenHelper.sol';
import {IWETH} from '../../interfaces/IWETH.sol';

import {ImmutablePeripheryStorage} from './ImmutablePeripheryStorage.sol';

abstract contract RouterTokenHelper is IRouterTokenHelper, ImmutablePeripheryStorage {
  constructor(address _factory, address _WETH) ImmutablePeripheryStorage(_factory, _WETH) {}

  receive() external payable {
    require(msg.sender == WETH, 'Not WETH');
  }

  /// @dev Unwrap all ETH balance and send to the recipient
  function unwrapWeth(uint256 minAmount, address recipient) external payable override {
    uint256 balanceWETH = IWETH(WETH).balanceOf(address(this));
    require(balanceWETH >= minAmount, 'Insufficient WETH');

    if (balanceWETH > 0) {
      IWETH(WETH).withdraw(balanceWETH);
      TokenHelper.transferEth(recipient, balanceWETH);
    }
  }

  /// @dev Transfer all tokens from the contract to the recipient
  function transferAllTokens(
    address token,
    uint256 minAmount,
    address recipient
  ) public payable virtual override {
    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= minAmount, 'Insufficient token');

    if (balanceToken > 0) {
      TokenHelper.transferToken(IERC20(token), balanceToken, address(this), recipient);
    }
  }

  /// @dev Send all ETH balance of this contract to the sender
  function refundEth() external payable override {
    if (address(this).balance > 0) TokenHelper.transferEth(msg.sender, address(this).balance);
  }

  /// @dev Transfer tokenAmount amount of token from the sender to the recipient
  function _transferTokens(
    address token,
    address sender,
    address recipient,
    uint256 tokenAmount
  ) internal {
    if (token == WETH && address(this).balance >= tokenAmount) {
      IWETH(WETH).deposit{value: tokenAmount}();
      IWETH(WETH).transfer(recipient, tokenAmount);
    } else {
      TokenHelper.transferToken(IERC20(token), tokenAmount, sender, recipient);
    }
  }
}