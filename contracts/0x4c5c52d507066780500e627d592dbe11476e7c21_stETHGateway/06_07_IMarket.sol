// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMarket {
  /**********
   * Events *
   **********/

  /// @notice Emitted when fToken or xToken is minted.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param fTokenOut The amount of fToken minted.
  /// @param xTokenOut The amount of xToken minted.
  /// @param mintFee The amount of mint fee charged.
  event Mint(
    address indexed owner,
    address indexed recipient,
    uint256 baseTokenIn,
    uint256 fTokenOut,
    uint256 xTokenOut,
    uint256 mintFee
  );

  /// @notice Emitted when someone redeem base token with fToken or xToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param xTokenBurned The amount of xToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param redeemFee The amount of redeem fee charged.
  event Redeem(
    address indexed owner,
    address indexed recipient,
    uint256 fTokenBurned,
    uint256 xTokenBurned,
    uint256 baseTokenOut,
    uint256 redeemFee
  );

  /// @notice Emitted when someone add more base token.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param xTokenMinted The amount of xToken minted.
  event AddCollateral(address indexed owner, address indexed recipient, uint256 baseTokenIn, uint256 xTokenMinted);

  /// @notice Emitted when someone liquidate with fToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  event UserLiquidate(address indexed owner, address indexed recipient, uint256 fTokenBurned, uint256 baseTokenOut);

  /// @notice Emitted when self liquidate with fToken.
  /// @param caller The address of caller.
  /// @param baseSwapAmt The amount of base token used to swap.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param fTokenBurned The amount of fToken liquidated.
  event SelfLiquidate(address indexed caller, uint256 baseSwapAmt, uint256 baseTokenOut, uint256 fTokenBurned);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint both fToken and xToken with some base token.
  /// @param baseIn The amount of base token supplied.
  /// @param recipient The address of receiver for fToken and xToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mint(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted,
    uint256 minXTokenMinted
  ) external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint some fToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for fToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  function mintFToken(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted
  ) external returns (uint256 fTokenMinted);

  /// @notice Mint some xToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mintXToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Mint some xToken by add some base token as collateral.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function addBaseToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Redeem base token with fToken and xToken.
  /// @param fTokenIn the amount of fToken to redeem, use `uint256(-1)` to redeem all fToken.
  /// @param xTokenIn the amount of xToken to redeem, use `uint256(-1)` to redeem all xToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Permissionless liquidate some fToken to increase the collateral ratio.
  /// @param fTokenIn the amount of fToken to supply, use `uint256(-1)` to liquidate all fToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function liquidate(
    uint256 fTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate some fToken to increase the collateral ratio.
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param minFTokenLiquidated The minimum amount of fToken should be liquidated.
  /// @param data The data used to swap base token to fToken.
  /// @return baseOut The amount of base token should be received.
  /// @return fTokenLiquidated the amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 minFTokenLiquidated,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fTokenLiquidated);

  /// @notice Callback to swap base token to fToken
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param data The data passed to market contract.
  /// @return fTokenAmt The amount of fToken received.
  function onSelfLiquidate(uint256 baseSwapAmt, bytes calldata data) external returns (uint256 fTokenAmt);
}