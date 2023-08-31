// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITreasury {
  /**********
   * Events *
   **********/

  /// @notice Emitted when the net asset value is updated.
  /// @param price The new price of base token.
  /// @param fNav The new net asset value of fToken.
  event ProtocolSettle(uint256 price, uint256 fNav);

  /*********
   * Enums *
   *********/

  enum MintOption {
    Both,
    FToken,
    XToken
  }

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the address of base token.
  function baseToken() external view returns (address);

  /// @notice Return the address fractional base token.
  function fToken() external view returns (address);

  /// @notice Return the address leveraged base token.
  function xToken() external view returns (address);

  /// @notice Return the address of strategy contract.
  function strategy() external view returns (address);

  /// @notice The last updated permissioned base token price.
  function lastPermissionedPrice() external view returns (uint256);

  /// @notice Return the total amount of base token deposited.
  function totalBaseToken() external view returns (uint256);

  /// @notice Return the total amount of base token managed by strategy.
  function strategyUnderlying() external view returns (uint256);

  /// @notice Return the current collateral ratio of fToken, multipled by 1e18.
  function collateralRatio() external view returns (uint256);

  /// @notice Return current nav for base token, fToken and xToken.
  /// @return baseNav The nav for base token.
  /// @return fNav The nav for fToken.
  /// @return xNav The nav for xToken.
  function getCurrentNav()
    external
    view
    returns (
      uint256 baseNav,
      uint256 fNav,
      uint256 xNav
    );

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxFTokenMintable The amount of fToken can be minted.
  function maxMintableFToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxFTokenMintable);

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxXTokenMintable);

  /// @notice Compute the amount of base token needed to reach the new collateral ratio, with incentive.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXTokenWithIncentive(uint256 newCollateralRatio, uint256 incentiveRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxXTokenMintable);

  /// @notice Compute the amount of fToken needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseOut The amount of base token redeemed.
  /// @return maxFTokenRedeemable The amount of fToken needed.
  function maxRedeemableFToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxFTokenRedeemable);

  /// @notice Compute the amount of xToken needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseOut The amount of base token redeemed.
  /// @return maxXTokenRedeemable The amount of xToken needed.
  function maxRedeemableXToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxXTokenRedeemable);

  /// @notice Compute the maximum amount of fToken can be liquidated.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return maxBaseOut The maximum amount of base token can liquidate, without incentive.
  /// @return maxFTokenLiquidatable The maximum amount of fToken can be liquidated.
  function maxLiquidatable(uint256 newCollateralRatio, uint256 incentiveRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxFTokenLiquidatable);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint fToken and xToken with some base token.
  /// @param baseIn The amount of base token deposited.
  /// @param recipient The address of receiver.
  /// @param option The mint option, xToken or fToken or both.
  /// @return fTokenOut The amount of fToken minted.
  /// @return xTokenOut The amount of xToken minted.
  function mint(
    uint256 baseIn,
    address recipient,
    MintOption option
  ) external returns (uint256 fTokenOut, uint256 xTokenOut);

  /// @notice Redeem fToken and xToken to base tokne.
  /// @param fTokenIn The amount of fToken to redeem.
  /// @param xTokenIn The amount of xToken to redeem.
  /// @param owner The owner of the fToken or xToken.
  /// @param baseOut The amount of base token redeemed.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address owner
  ) external returns (uint256 baseOut);

  /// @notice Add some base token to mint xToken with incentive.
  /// @param baseIn The amount of base token deposited.
  /// @param incentiveRatio The incentive ratio.
  /// @param recipient The address of receiver.
  /// @return xTokenOut The amount of xToken minted.
  function addBaseToken(
    uint256 baseIn,
    uint256 incentiveRatio,
    address recipient
  ) external returns (uint256 xTokenOut);

  /// @notice Liquidate fToken to base token with incentive.
  /// @param fTokenIn The amount of fToken to liquidate.
  /// @param incentiveRatio The incentive ratio.
  /// @param owner The owner of the fToken.
  /// @param baseOut The amount of base token liquidated.
  function liquidate(
    uint256 fTokenIn,
    uint256 incentiveRatio,
    address owner
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate fToken to base token with incentive.
  /// @param baseSwapAmt The amount of base token used to buy fToken.
  /// @param incentiveRatio The incentive ratio.
  /// @param recipient The address of receiver of profited base token.
  /// @param data The calldata passed to market contract.
  /// @return baseOut The expected base token received.
  /// @return fAmt The amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 incentiveRatio,
    address recipient,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fAmt);

  /// @notice Settle the nav of base token, fToken and xToken.
  function protocolSettle() external;

  /// @notice Transfer some base token to strategy contract.
  /// @param amount The amount of token to transfer.
  function transferToStrategy(uint256 amount) external;

  /// @notice Notify base token profit from strategy contract.
  /// @param amount The amount of base token.
  function notifyStrategyProfit(uint256 amount) external;
}