// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IPairManager.sol';
import '../contracts/libraries/PoolAddress.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './peripherals/IGovernable.sol';

/// @title Pair Manager contract
/// @notice Creates a UniswapV3 position, and tokenizes in an ERC20 manner
///         so that the user can use it as liquidity for a Keep3rJob
interface IUniV3PairManager is IGovernable, IPairManager {
  // Structs

  /// @notice The data to be decoded by the UniswapV3MintCallback function
  struct MintCallbackData {
    PoolAddress.PoolKey _poolKey; // Struct that contains token0, token1, and fee of the pool passed into the constructor
    address payer; // The address of the payer, which will be the msg.sender of the mint function
  }

  // Variables

  /// @notice The fee of the Uniswap pool passed into the constructor
  /// @return _fee The fee of the Uniswap pool passed into the constructor
  function fee() external view returns (uint24 _fee);

  /// @notice Highest tick in the Uniswap's curve
  /// @return _tickUpper The highest tick in the Uniswap's curve
  function tickUpper() external view returns (int24 _tickUpper);

  /// @notice Lowest tick in the Uniswap's curve
  /// @return _tickLower The lower tick in the Uniswap's curve
  function tickLower() external view returns (int24 _tickLower);

  /// @notice The pair tick spacing
  /// @return _tickSpacing The pair tick spacing
  function tickSpacing() external view returns (int24 _tickSpacing);

  /// @notice The sqrtRatioAX96 at the lowest tick (-887200) of the Uniswap pool
  /// @return _sqrtPriceA96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  ///         at the lowest tick
  function sqrtRatioAX96() external view returns (uint160 _sqrtPriceA96);

  /// @notice The sqrtRatioBX96 at the highest tick (887200) of the Uniswap pool
  /// @return _sqrtPriceBX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  ///         at the highest tick
  function sqrtRatioBX96() external view returns (uint160 _sqrtPriceBX96);

  // Errors

  /// @notice Throws when the caller of the function is not the pool
  error OnlyPool();

  /// @notice Throws when the slippage exceeds what the user is comfortable with
  error ExcessiveSlippage();

  /// @notice Throws when a transfer is unsuccessful
  error UnsuccessfulTransfer();

  // Methods

  /// @notice This function is called after a user calls IUniV3PairManager#mint function
  ///         It ensures that any tokens owed to the pool are paid by the msg.sender of IUniV3PairManager#mint function
  /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
  /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
  /// @param data The encoded token0, token1, fee (_poolKey) and the payer (msg.sender) of the IUniV3PairManager#mint function
  function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
  ) external;

  /// @notice Mints kLP tokens to an address according to the liquidity the msg.sender provides to the UniswapV3 pool
  /// @dev Triggers UniV3PairManager#uniswapV3MintCallback
  /// @param amount0Desired The amount of token0 we would like to provide
  /// @param amount1Desired The amount of token1 we would like to provide
  /// @param amount0Min The minimum amount of token0 we want to provide
  /// @param amount1Min The minimum amount of token1 we want to provide
  /// @param to The address to which the kLP tokens are going to be minted to
  /// @return liquidity kLP tokens sent in exchange for the provision of tokens
  function mint(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external returns (uint128 liquidity);

  /// @notice Returns the pair manager's position in the corresponding UniswapV3 pool
  /// @return liquidity The amount of liquidity provided to the UniswapV3 pool by the pair manager
  /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
  /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
  /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
  /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
  function position()
    external
    view
    returns (
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  /// @notice Calls the UniswapV3 pool's collect function, which collects up to a maximum amount of fees
  //          owed to a specific position to the recipient, in this case, that recipient is the pair manager
  /// @dev The collected fees will be sent to governance
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect() external returns (uint256 amount0, uint256 amount1);

  /// @notice Burns the corresponding amount of kLP tokens from the msg.sender and withdraws the specified liquidity
  //          in the entire range
  /// @param liquidity The amount of liquidity to be burned
  /// @param amount0Min The minimum amount of token0 we want to send to the recipient (to)
  /// @param amount1Min The minimum amount of token1 we want to send to the recipient (to)
  /// @param to The address that will receive the due fees
  /// @return amount0 The calculated amount of token0 that will be sent to the recipient
  /// @return amount1 The calculated amount of token1 that will be sent to the recipient
  function burn(
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external returns (uint256 amount0, uint256 amount1);
}