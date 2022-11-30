// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import {SeniorPool} from "../protocol/core/SeniorPool.sol";

contract TestSeniorPool is SeniorPool {
  function _getNumShares(uint256 amount) public view returns (uint256) {
    return getNumShares(amount);
  }

  function getUSDCAmountFromShares(uint256 fiduAmount) public view returns (uint256) {
    return _getUSDCAmountFromShares(fiduAmount);
  }

  function __getNumShares(uint256 usdcAmount, uint256 sharePrice) public pure returns (uint256) {
    return _getNumShares(usdcAmount, sharePrice);
  }

  function usdcMantissa() public pure returns (uint256) {
    return USDC_MANTISSA;
  }

  function fiduMantissa() public pure returns (uint256) {
    return FIDU_MANTISSA;
  }

  function usdcToFidu(uint256 amount) public pure returns (uint256) {
    return _usdcToFidu(amount);
  }

  function _setSharePrice(uint256 newSharePrice) public returns (uint256) {
    sharePrice = newSharePrice;
  }

  function epochAt(uint256 id) external view returns (Epoch memory) {
    return _epochs[id];
  }
}