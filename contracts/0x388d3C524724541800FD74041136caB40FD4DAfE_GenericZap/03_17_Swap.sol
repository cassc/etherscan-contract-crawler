pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWeth.sol";
import "./Executable.sol";
import "./EthConstants.sol";


/// @notice An inlined library for liquidity pool related helper functions.
library Swap {
  
  // @dev calling function should ensure targets are approved 
  function fillQuote(
    address _fromToken,
    uint256 _fromAmount,
    address _toToken,
    address _swapTarget,
    bytes memory _swapData
  ) internal returns (uint256) {
    if (_swapTarget == EthConstants.WETH) {
      require(_fromToken == EthConstants.WETH, "Swap: Invalid from token and WETH target");
      require(
        _fromAmount > 0 && msg.value == _fromAmount,
        "Swap: Input ETH mismatch"
      );
      IWETH(EthConstants.WETH).deposit{value: _fromAmount}();
      return _fromAmount;
    }

    uint256 amountBought;
    uint256 valueToSend;
    if (_fromToken == address(0)) {
      require(
        _fromAmount > 0 && msg.value == _fromAmount,
        "Swap: Input ETH mismatch"
      );
      valueToSend = _fromAmount;
    } else {
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), _swapTarget, _fromAmount);
    }

    // to calculate amount received
    uint256 initialBalance = IERC20(_toToken).balanceOf(address(this));

    // we don't need the returndata here
    Executable.execute(_swapTarget, valueToSend, _swapData);
    unchecked {
      amountBought = IERC20(_toToken).balanceOf(address(this)) - initialBalance;
    }

    return amountBought;
  }

  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) internal view returns (uint256) {
    address token0 = IUniswapV2Pair(_pair).token0();
    (uint112 reserveA, uint112 reserveB,) = IUniswapV2Pair(_pair).getReserves();
    uint256 reserveIn = token0 == _token ? reserveA : reserveB;
    uint256 amountToSwap = calculateSwapInAmount(reserveIn, _amount);
    return amountToSwap;
  }

  function calculateSwapInAmount(
    uint256 reserveIn,
    uint256 userIn
  ) internal pure returns (uint256) {
    return
        (sqrt(
            reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
        ) - (reserveIn * 1997)) / 1994;
  }

  // borrowed from Uniswap V2 Core Math library https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
          z = x;
          x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  /** 
    * given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    *
    * Direct copy of UniswapV2Library.quote(amountA, reserveA, reserveB) - can't use as directly as it's built off a different version of solidity
    */
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(reserveA > 0 && reserveB > 0, "Swap: Insufficient liquidity");
    amountB = (amountA * reserveB) / reserveA;
  }

  function getPairTokens(
    address _pairAddress
  ) internal view returns (address token0, address token1) {
    IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
    token0 = pair.token0();
    token1 = pair.token1();
  }

}