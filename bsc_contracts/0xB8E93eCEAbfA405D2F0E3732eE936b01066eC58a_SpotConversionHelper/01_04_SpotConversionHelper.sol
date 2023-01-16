// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

contract SpotConversionHelper {
  using Address for address;

  address private constant UNISWAPROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

  // Hop depth for supported spot conversion tokens:
  // Hop depth is used to determine the path for for estimates and swaps.
  // - QUINT -> 2
  // - WETH  -> 2
  // - USDT  -> 1
  // - BTBC  -> 1
  address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address public constant QUINT = 0x64619f611248256F7F4b72fE83872F89d5d60d64;
  address public constant WETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
  address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
  address public constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

  IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

  /**
   * @dev modifier to check if the token is a valid spot conversion option.
   * @param token -> The address of the token to convert.
   */
  modifier isValidPaymentOption(address token) {
    require(
      token == QUINT || token == WETH || token == USDT || token == BTCB,
      "SpotConversionHelper: Not valid payment option"
    );
    _;
  }

  constructor() {}

  /**
   * @dev Swap using the UniswapV2Router contract and returns the exact amount of token out
   * @param token -> The address of the token to be swapped.
   * @param amountOut -> The desired amount of BUSD out.
   * @param amountIn -> The amount of token x to be swapped for BUSD.
   * @return -> The exact amount of BUSD received.
   */
  function swapTokenExactAmountOutForBUSD(
    address token,
    uint256 amountOut,
    uint256 amountIn
  ) public isValidPaymentOption(token) returns (uint256) {
    IERC20(token).transferFrom(msg.sender, address(this), amountIn);
    IERC20(token).approve(address(uniswapV2Router), amountIn);

    if (getHopDepthForToken(token) == 1) {
      address[] memory path = getPathForHopSingle(token);
      uint256[] memory amounts = uniswapV2Router.swapTokensForExactTokens(
        amountOut,
        amountIn,
        path,
        msg.sender,
        block.timestamp
      );

      if (amounts[0] < amountIn) {
        IERC20(token).transfer(msg.sender, amountIn - amounts[0]);
      }
      return amounts[1];
    } else {
      address[] memory path = getPathForHopMulti(token);
      uint256[] memory amounts = uniswapV2Router.swapTokensForExactTokens(
        amountOut,
        amountIn,
        path,
        msg.sender,
        block.timestamp
      );

      if (amounts[0] < amountIn) {
        IERC20(token).transfer(msg.sender, amountIn - amounts[0]);
      }
      return amounts[2];
    }
  }

  /**
   * @dev Get the estimated amount of token x in required to receive a specific amount of BUSD.
   * @param token -> The address of the token to be swapped.
   * @param amountOut -> The desired amount of BUSD out.
   * @return -> Token in required to receive the desired amount of BUSD.
   */
  function getEstimatedTokenAmountForBUSD(address token, uint256 amountOut)
    public
    view
    isValidPaymentOption(token)
    returns (uint256[] memory)
  {
    if (getHopDepthForToken(token) == 1) {
      return uniswapV2Router.getAmountsIn(amountOut, getPathForHopSingle(token));
    } else {
      return uniswapV2Router.getAmountsIn(amountOut, getPathForHopMulti(token));
    }
  }

  /**
   * @dev Get the hop depth for a specific token.
   * @param token -> The address of the token.
   * @return hopDepth -> The hop depth for the token.
   */
  function getHopDepthForToken(address token) private pure returns (uint256 hopDepth) {
    if (token == QUINT) {
      return 2;
    }
    if (token == WETH) {
      return 2;
    }
    if (token == USDT) {
      return 1;
    }
    if (token == BTCB) {
      return 1;
    }
  }

  /**
   * @dev Get the path for a single hop swap for a specific token.
   * @param token -> The address of the token.
   * @return -> The path for a single hop swap for the token.
   */
  function getPathForHopSingle(address token) private pure returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = BUSD;

    return path;
  }

  /**
   * @dev Get the path for a multi hop swap for a specific token
   * @param token -> The address of the token.
   * @return -> The path for a multi hop swap for the token.
   */
  function getPathForHopMulti(address token) private view returns (address[] memory) {
    address[] memory path = new address[](3);

    path[0] = token;
    path[1] = uniswapV2Router.WETH();
    path[2] = BUSD;

    return path;
  }
}