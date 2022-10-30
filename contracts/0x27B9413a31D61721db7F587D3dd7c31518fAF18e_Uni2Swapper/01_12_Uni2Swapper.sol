// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/ISwapper.sol";
import "../dex/uniswap/interfaces/IUniswapV2Pair.sol";
import "../proxy/ControllableV3.sol";

/// @title Swap tokens via UniswapV2 contracts.
/// @author belbix
contract Uni2Swapper is ControllableV3, ISwapper {
  using SafeERC20 for IERC20;

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant UNI_SWAPPER_VERSION = "1.0.1";
  uint public constant FEE_DENOMINATOR = 100_000;
  uint public constant PRICE_IMPACT_DENOMINATOR = 100_000;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  mapping(address => uint) public feeByFactory;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event Swap(
    address pool,
    address tokenIn,
    address tokenOut,
    address recipient,
    uint priceImpactTolerance,
    uint amountIn,
    uint amountOut
  );
  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Proxy initialization. Call it after contract deploy.
  function init(address controller_) external initializer {
    __Controllable_init(controller_);
  }

  // *************************************************************
  //                     GOV ACTIONS
  // *************************************************************

  /// @dev Set fee for given factory. Denominator is 100_000.
  function setFee(address factory, uint fee) external {
    require(isGovernance(msg.sender), "DENIED");

    feeByFactory[factory] = fee;
  }

  // *************************************************************
  //                        PRICE
  // *************************************************************

  function getPrice(
    address pool,
    address tokenIn,
    address tokenOut,
    uint amount
  ) external view override returns (uint) {
    (uint reserveIn, uint reserveOut) = _getReserves(IUniswapV2Pair(pool), tokenIn, tokenOut);
    uint fee = feeByFactory[IUniswapV2Pair(pool).factory()];
    return _getAmountOut(amount, reserveIn, reserveOut, fee);
  }

  // *************************************************************
  //                        SWAP
  // *************************************************************

  /// @dev Swap given tokenIn for tokenOut. Assume that tokenIn already sent to this contract.
  /// @param pool UniswapV2 pool
  /// @param tokenIn Token for sell
  /// @param tokenOut Token for buy
  /// @param recipient Recipient for tokenOut
  /// @param priceImpactTolerance Price impact tolerance. Must include fees at least. Denominator is 100_000.
  function swap(
    address pool,
    address tokenIn,
    address tokenOut,
    address recipient,
    uint priceImpactTolerance
  ) external override {
    uint amount0Out;
    uint amount1Out;
    uint amountIn = IERC20(tokenIn).balanceOf(address(this));

    {
      uint fee = feeByFactory[IUniswapV2Pair(pool).factory()];

      require(fee != 0, "ZERO_FEE");

      (uint reserveIn, uint reserveOut) = _getReserves(IUniswapV2Pair(pool), tokenIn, tokenOut);
      uint amountOut = _getAmountOut(amountIn, reserveIn, reserveOut, fee);

      uint amountOutMax = getAmountOutMax(reserveIn, reserveOut, amountIn);

      require((amountOutMax - amountOut) * PRICE_IMPACT_DENOMINATOR / amountOutMax <= priceImpactTolerance, "!PRICE");

      (address token0,) = _sortTokens(tokenIn, tokenOut);
      (amount0Out, amount1Out) = tokenIn == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

      IERC20(tokenIn).safeTransfer(pool, amountIn);
    }

    IUniswapV2Pair(pool).swap(
      amount0Out,
      amount1Out,
      recipient,
      new bytes(0)
    );

    emit Swap(
      pool,
      tokenIn,
      tokenOut,
      recipient,
      priceImpactTolerance,
      amountIn,
      amount0Out == 0 ? amount1Out : amount0Out
    );
  }

  function getAmountOutMax(
    uint reserveIn,
    uint reserveOut,
    uint amountIn
  ) public pure returns (uint) {
    return amountIn * 1e18 / (reserveIn * 1e18 / reserveOut);
  }

  /// @dev Fetches and sorts the reserves for a pair.
  function _getReserves(
    IUniswapV2Pair _lp,
    address tokenA,
    address tokenB
  ) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = _sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = _lp.getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  /// @dev Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function _getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut,
    uint fee
  ) internal pure returns (uint amountOut) {
    uint amountInWithFee = amountIn * (FEE_DENOMINATOR - fee);
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  /// @dev Returns sorted token addresses, used to handle return values from pairs sorted in this order
  function _sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }
}