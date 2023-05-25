// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/Math.sol";
import "../openzeppelin/Strings.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/ISwapper.sol";
import "../dex/uniswap3/interfaces/IUniswapV3Pool.sol";
import "../proxy/ControllableV3.sol";
import "../dex/uniswap3/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Swap tokens via UniswapV3 contracts.
/// @author belbix
contract Uni3Swapper is ControllableV3, ISwapper, IUniswapV3SwapCallback {
  using SafeERC20 for IERC20;

  struct SwapCallbackData {
    address tokenIn;
    uint amount;
  }

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant UNI_SWAPPER3_VERSION = "1.0.3";
  uint public constant FEE_DENOMINATOR = 100_000;
  uint public constant PRICE_IMPACT_DENOMINATOR = 100_000;
  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739 + 1;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
  uint private constant TWO_96 = 2 ** 96;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

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
  //                        PRICE
  // *************************************************************

  function _countDigits(uint n) internal pure returns (uint){
    if (n == 0) {
      return 0;
    }
    uint count = 0;
    while (n != 0) {
      n = n / 10;
      ++count;
    }
    return count;
  }

  /// @dev Return current price without amount impact.
  function getPrice(
    address pool,
    address tokenIn,
    address /*tokenOut*/,
    uint amount
  ) public view override returns (uint) {
    address token0 = IUniswapV3Pool(pool).token0();
    address token1 = IUniswapV3Pool(pool).token1();

    uint256 tokenInDecimals = tokenIn == token0 ? IERC20Metadata(token0).decimals() : IERC20Metadata(token1).decimals();
    uint256 tokenOutDecimals = tokenIn == token1 ? IERC20Metadata(token0).decimals() : IERC20Metadata(token1).decimals();
    (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

    uint divider = tokenOutDecimals < 18 ? Math.max(10 ** tokenOutDecimals / 10 ** tokenInDecimals, 1) : 1;

    uint priceDigits = _countDigits(uint(sqrtPriceX96));
    uint purePrice;
    uint precision;
    if (tokenIn == token0) {
      precision = 10 ** ((priceDigits < 29 ? 29 - priceDigits : 0) + tokenInDecimals);
      uint part = uint(sqrtPriceX96) * precision / TWO_96;
      purePrice = part * part;
    } else {
      precision = 10 ** ((priceDigits > 29 ? priceDigits - 29 : 0) + tokenInDecimals);
      uint part = TWO_96 * precision / uint(sqrtPriceX96);
      purePrice = part * part;
    }
    uint price = purePrice / divider / precision / (precision > 1e18 ? (precision / 1e18) : 1);

    if (amount != 0) {
      return price * amount / (10 ** tokenInDecimals);
    } else {
      return price;
    }
  }

  // *************************************************************
  //                        SWAP
  // *************************************************************

  /// @dev Swap given tokenIn for tokenOut. Assume that tokenIn already sent to this contract.
  /// @param pool UniswapV3 pool
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
    address token0 = IUniswapV3Pool(pool).token0();

    uint balanceBefore = IERC20(tokenOut).balanceOf(recipient);
    uint amount = IERC20(tokenIn).balanceOf(address(this));

    {
      uint priceBefore = getPrice(pool, tokenIn, tokenOut, amount);

      IUniswapV3Pool(pool).swap(
        recipient,
        tokenIn == token0,
        int(amount),
        tokenIn == token0 ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
        abi.encode(SwapCallbackData(tokenIn, amount))
      );

      uint priceAfter = getPrice(pool, tokenIn, tokenOut, amount);
      // unreal but better to check
      require(priceAfter <= priceBefore, "Price increased");

      uint priceImpact = (priceBefore - priceAfter) * PRICE_IMPACT_DENOMINATOR / priceBefore;
      require(priceImpact < priceImpactTolerance, string(abi.encodePacked("!PRICE ", Strings.toString(priceImpact))));
    }

    uint balanceAfter = IERC20(tokenOut).balanceOf(recipient);
    emit Swap(
      pool,
      tokenIn,
      tokenOut,
      recipient,
      priceImpactTolerance,
      amount,
      balanceAfter > balanceBefore ? balanceAfter - balanceBefore : 0
    );
  }

  // *************************************************************
  //                     INTERNAL LOGIC
  // *************************************************************

  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata _data
  ) external override {
    require(amount0Delta > 0 || amount1Delta > 0, "Wrong callback amount");
    SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
    IERC20(data.tokenIn).safeTransfer(msg.sender, data.amount);
  }

}