// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/ILiquidityCaptor.sol";

import "../external/IUniswapV2Factory.sol";
import "../external/IUniswapV2Pair.sol";
import "../external/UniswapV2Library.sol";

contract LiquidityCaptor is AccessControl, ILiquidityCaptor {
  using SafeERC20 for IERC20;

  uint256 private constant WAD = 10**18;

  /// @notice Role for setting important parameters
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Role for run `captureLiquidity`
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @notice Uniswap V2 Pair address of the BLU token and the reserve token
  address public immutable targetPool;

  /// @notice Address of the reserve token
  address public immutable reserveToken;

  /// @notice Address of the BLU token
  address public immutable bluToken;

  /// @notice Cache of BLU token position on the Uniswap Pair
  bool public immutable bluIsToken0;

  /// @notice Address of the treasury contract
  ITreasury public immutable treasury;

  /// @notice Minimum price of BLU token against reserve token after any swaps, in reserve tokens's decimal
  uint256 public minPrice;

  /// @notice Maximum discount ratio, in WAD
  uint256 public maxDiscount;

  /// @notice Minimum amount of time to wait between executing `captureLiquidity`, in seconds
  uint256 public period;

  /// @notice Timestamp where `captureLiquidity` is last ran, in unix epoch time
  uint256 public lastCapture;

  /// @notice Constructor to initialize the contract
  /// @param _reserveToken Address of the reserve token
  /// @param _bluToken Address of the BLU token
  /// @param _targetPool Uniswap V2 Pair address of the BLU token and the reserve token
  /// @param _treasury Address of the treasury contract
  /// @param _minPrice Minimum price of BLU token against reserve token after any swaps, in reserve tokens's decimal
  /// @param _maxDiscount Maximum discount ratio, in WAD
  /// @param _period Minimum amount of time to wait between executing `captureLiquidity`, in seconds
  constructor(
    address _reserveToken,
    address _bluToken,
    address _targetPool,
    address _treasury,
    uint256 _minPrice,
    uint256 _maxDiscount,
    uint256 _period
  ) {
    require(_maxDiscount < WAD, "Discount must be less than WAD");
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    reserveToken = _reserveToken;
    bluToken = _bluToken;
    targetPool = _targetPool;
    treasury = ITreasury(_treasury);
    minPrice = _minPrice;
    maxDiscount = _maxDiscount;
    period = _period;

    (address token0, ) = UniswapV2Library.sortTokens(_bluToken, _reserveToken);
    bluIsToken0 = token0 == _bluToken;
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to swap BLU tokens for reserve tokens on the Uniswap V2 Pair
  /// @param bluAmountIn Amount of BLU tokens to swap, in WAD
  /// @param minReserveAmountOut Minimum amount of reserve tokens to expect from the swap, in reserve tokens's decimal
  /// @return amountOut Amount of reserve token from the swap, in reserve tokens's decimal
  function _swapToReserve(uint256 bluAmountIn, uint256 minReserveAmountOut)
    internal
    onlyRole(OPERATOR_ROLE)
    returns (uint256 amountOut)
  {
    IUniswapV2Pair pool = IUniswapV2Pair(targetPool);

    // Determine expected amount of reserve received swapping BLU
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
    amountOut = UniswapV2Library.getAmountOut(
      bluAmountIn,
      bluIsToken0 ? reserve0 : reserve1,
      bluIsToken0 ? reserve1 : reserve0
    );
    require(amountOut >= minReserveAmountOut, "Insufficient output");

    // Transfer BLU token to pool
    treasury.mint(targetPool, bluAmountIn);

    // Perform the swap and send reserve token to this address
    pool.swap(
      bluIsToken0 ? 0 : amountOut,
      bluIsToken0 ? amountOut : 0,
      address(this),
      new bytes(0)
    );
  }

  // =============================== OPERATOR_ROLE FUNCTIONS =================================

  /// @notice Capture liquidity by swapping BLU tokens for reserve and then adding them back in as liquidity.
  /// Liquidity tokens are sent to the treasury as protocol's asset.
  /// @param bluAmountIn Amount of BLU tokens to swap, in WAD
  /// @param minReserveAmountOut Minimum amount of reserve tokens to expect from the swap, in reserve tokens's decimal
  /// @return reserveAmountOut Amount of reserve tokens received from the swap, in reserve tokens's decimal
  /// @return liquidity Amount of liquidity tokens received from adding liquidity
  function captureLiquidity(uint256 bluAmountIn, uint256 minReserveAmountOut)
    public
    override
    onlyRole(OPERATOR_ROLE)
    returns (uint256 reserveAmountOut, uint256 liquidity)
  {
    require(lastCapture + period < block.timestamp, "Period has not elapsed");
    (uint256 bluReserve, uint256 reserveReserve) = getReserves();
    uint256 initialPrice = (reserveReserve * WAD) / bluReserve;

    // Swap BLU to reserve token
    reserveAmountOut = _swapToReserve(bluAmountIn, minReserveAmountOut);

    // Determine BLU token needed to add as liquidity to the pool
    (bluReserve, reserveReserve) = getReserves();
    uint256 bluToMint = (reserveAmountOut * bluReserve) / reserveReserve;

    // Transfer both tokens to pool
    IERC20(reserveToken).safeTransfer(targetPool, reserveAmountOut);
    treasury.mint(targetPool, bluToMint);

    // Finally add the liquidity and send LP token to treasury
    liquidity = IUniswapV2Pair(targetPool).mint(address(treasury));

    // Ensure that final spot price is above the minimum price
    (bluReserve, reserveReserve) = getReserves();
    uint256 finalPrice = (reserveReserve * WAD) / bluReserve;

    // Check that excessive swap did not occur
    require(
      finalPrice >= (initialPrice * (WAD - maxDiscount)) / WAD,
      "Excessive Discount"
    );
    require(finalPrice >= minPrice, "Price too low");

    // Update last capture time
    lastCapture = block.timestamp;
    emit LiquidityCaptured(bluAmountIn, reserveAmountOut, liquidity);
  }

  // =============================== MANAGER FUNCTIONS =================================

  /// @notice Set maximum discount ratio, in WAD
  /// @param _maxDiscount Maximum discount ratio, in WAD
  function setMaxDiscount(uint256 _maxDiscount)
    public
    override
    onlyRole(MANAGER_ROLE)
  {
    require(_maxDiscount < WAD, "Discount must be less than WAD");
    maxDiscount = _maxDiscount;
  }

  /// @notice Set minimum amount of time to wait between executing `captureLiquidity`
  /// @param _period Minimum time to wait, in seconds
  function setPeriod(uint256 _period) public override onlyRole(MANAGER_ROLE) {
    period = _period;
  }

  /// @notice Set minimum price of BLU token
  /// @param _minPrice Minimum price, in reserve tokens's decimal
  function setMinPrice(uint256 _minPrice)
    public
    override
    onlyRole(MANAGER_ROLE)
  {
    minPrice = _minPrice;
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get sorted reserves from the Uniswap V2 Pair
  /// @return bluReserve BLU token reserve, in WAD
  /// @return reserveReserve Reserve token reserve, in reserve tokens's decimal
  function getReserves()
    public
    view
    override
    returns (uint256 bluReserve, uint256 reserveReserve)
  {
    IUniswapV2Pair pool = IUniswapV2Pair(targetPool);
    (reserveReserve, bluReserve, ) = pool.getReserves();
    if (bluIsToken0) {
      (reserveReserve, bluReserve) = (bluReserve, reserveReserve);
    }
  }
}