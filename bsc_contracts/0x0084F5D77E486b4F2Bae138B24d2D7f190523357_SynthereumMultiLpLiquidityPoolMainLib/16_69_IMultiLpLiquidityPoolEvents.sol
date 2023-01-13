// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumMultiLpLiquidityPoolEvents {
  struct MintValues {
    // collateral sent to the the pool by the user
    uint256 totalCollateral;
    // numTokens * price
    uint256 exchangeAmount;
    // Fee to be paid according to the fee percentage
    uint256 feeAmount;
    // Number of synthetic tokens will be received ((totalCollateral - feeAmount - lending fee/bonus) / price)
    uint256 numTokens;
  }

  struct RedeemValues {
    // Amount of synthetic asset sent by the user
    uint256 numTokens;
    // numTokens * price
    uint256 exchangeAmount;
    // Fee to be paid according to the fee percentage
    uint256 feeAmount;
    // Net collateral amount will be received (totCollateral - feeAmount -lending fee/bonus )
    uint256 collateralAmount;
  }

  /**
   * @notice Emitted when a LP is registered in the pool by the maintainer
   * @param lp Address of the LP to be registered
   */
  event RegisteredLp(address indexed lp);

  /**
   * @notice Emitted when a LP is activated in the pool by himself
   * @param lp Address of the LP to be activated
   */
  event ActivatedLP(address indexed lp);

  /**
   * @notice Emitted when a LP set his overCollateralization
   * @param lp Address of the LP to set overCollateralization
   * @param overCollateralization OverCollateralization percentage set
   */
  event SetOvercollateralization(
    address indexed lp,
    uint256 overCollateralization
  );

  /**
   * @notice Emitted when a LP deposits collateral
   * @param lp Address of the LP depositing
   * @param collateralSent Collateral sent to the the pool by the LP
   * @param collateralDeposited Net collateral amount added to the LP position
   */
  event DepositedLiquidity(
    address indexed lp,
    uint256 collateralSent,
    uint256 collateralDeposited
  );

  /**
   * @notice Emitted when a LP withdraws collateral
   * @param lp Address of the LP withdrawing
   * @param collateralWithdrawn Collateral amount removed from the LP position
   * @param collateralReceived Collateral received from the pool by the LP
   */
  event WithdrawnLiquidity(
    address indexed lp,
    uint256 collateralWithdrawn,
    uint256 collateralReceived
  );

  /**
   * @notice Emitted when a user mint the synthetic asset
   * @param user Address of the user minting
   * @param mintvalues Include netCollateralAmount, feeAmount and numTokens
   * @param recipient Address receiving minted tokens
   */
  event Minted(address indexed user, MintValues mintvalues, address recipient);

  /**
   * @notice Emitted when a user redeem the synthetic asset
   * @param user Address of the user redeeming
   * @param redeemvalues Include exchangeAmount, feeAmount and collateralAmount
   * @param recipient Address receiving collateral unlocked
   */
  event Redeemed(
    address indexed user,
    RedeemValues redeemvalues,
    address recipient
  );

  /**
   * @notice Emitted when a user liquidate an LP
   * @param user Address of the user liquidating
   * @param lp Address of the LP to liquidate
   * @param synthTokensInLiquidation Amount of synthetic asset in liquidation
   * @param collateralAmount Value of synthetic tokens in liquidation expressed in collateral (synthTokensInLiquidation * price)
   * @param bonusAmount Collateral amount as reward for the liquidator
   * @param collateralReceived Amount of collateral received by liquidator (collateralAmount + liquidation bonus - lending fee/bonus)
   */
  event Liquidated(
    address indexed user,
    address indexed lp,
    uint256 synthTokensInLiquidation,
    uint256 collateralAmount,
    uint256 bonusAmount,
    uint256 collateralReceived
  );

  /**
   * @notice Emitted when new fee percentage is set in the pool by the maintainer
   * @param newFee New fee percentage
   */
  event SetFeePercentage(uint256 newFee);

  /**
   * @notice Emitted when liquidation reward percentage is set in the pool by the maintainer
   * @param newLiquidationReward New liquidation reward percentage
   */
  event SetLiquidationReward(uint256 newLiquidationReward);

  /**
   * @notice Emitted when lending module is initialized or set
   * @param lendingModuleId Name of the lending module
   */
  event NewLendingModule(string lendingModuleId);
}