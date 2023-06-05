// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @dev parameter for minting Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To The address of the recipient of TimeswapV2Token representing long0 position.
/// @param long1To The address of the recipient of TimeswapV2Token representing long1 position.
/// @param shortTo The address of the recipient of TimeswapV2Token representing short position.
/// @param long0Amount The amount of long0 deposited.
/// @param long1Amount The amount of long1 deposited.
/// @param shortAmount The amount of short deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2TokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param long0To  The address of the recipient of long token0 position.
/// @param long1To The address of the recipient of long token1 position.
/// @param shortTo The address of the recipient of short position.
/// @param long0Amount  The amount of TimeswapV2Token long0  deposited and equivalent long0 position is withdrawn.
/// @param long1Amount The amount of TimeswapV2Token long1 deposited and equivalent long1 position is withdrawn.
/// @param shortAmount The amount of TimeswapV2Token short deposited and equivalent short position is withdrawn,
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2TokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev parameter for minting Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of TimeswapV2LiquidityToken.
/// @param liquidityAmount The amount of liquidity token deposited.
/// @param data Arbitrary data passed to the callback.
struct TimeswapV2LiquidityTokenMintParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev parameter for burning Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the liquidity token.
/// @param liquidityAmount The amount of liquidity token withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenBurnParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev parameter for adding long0, long1, and short into fees storage.
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the fees.
/// @param long0Fees The amount of long0 to be deposited.
/// @param long1Fees The amount of long1 to be deposited.
/// @param shortFees The amount of short to be deposited.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenAddFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev parameter for collecting fees from Timeswap V2 Liquidity Tokens
/// @param token0 The first ERC20 token address of the pair.
/// @param token1 The second ERC20 token address of the pair.
/// @param strike  The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param to The address of the recipient of the fees.
/// @param long0FeesDesired The maximum amount of long0Fees desired to be withdrawn.
/// @param long1FeesDesired The maximum amount of long1Fees desired to be withdrawn.
/// @param shortFeesDesired The maximum amount of shortFees desired to be withdrawn.
/// @param data Arbitrary data passed to the callback, initalize as empty if not required.
struct TimeswapV2LiquidityTokenCollectParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 long0FeesDesired;
  uint256 long1FeesDesired;
  uint256 shortFeesDesired;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks for token mint.
  function check(TimeswapV2TokenMintParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for token burn.
  function check(TimeswapV2TokenBurnParam memory param) internal pure {
    if (param.long0To == address(0) || param.long1To == address(0) || param.shortTo == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Amount == 0 && param.long1Amount == 0 && param.shortAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token mint.
  function check(TimeswapV2LiquidityTokenMintParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token burn.
  function check(TimeswapV2LiquidityTokenBurnParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.liquidityAmount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity add fees.
  function check(TimeswapV2LiquidityTokenAddFeesParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0Fees == 0 && param.long1Fees == 0 && param.shortFees == 0) Error.zeroInput();
  }

  /// @dev Sanity checks for liquidity token collect.
  function check(TimeswapV2LiquidityTokenCollectParam memory param) internal pure {
    if (param.to == address(0)) Error.zeroAddress();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.long0FeesDesired == 0 && param.long1FeesDesired == 0 && param.shortFeesDesired == 0) Error.zeroInput();
  }
}