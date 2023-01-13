// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  IEmergencyShutdown
} from '../../../common/interfaces/IEmergencyShutdown.sol';
import {ISynthereumLiquidityPoolGeneral} from './ILiquidityPoolGeneral.sol';
import {ISynthereumLiquidityPoolStorage} from './ILiquidityPoolStorage.sol';
import {ITypology} from '../../../common/interfaces/ITypology.sol';

/**
 * @title Token Issuer Contract Interface
 */
interface ISynthereumLiquidityPool is
  ITypology,
  IEmergencyShutdown,
  ISynthereumLiquidityPoolGeneral
{
  struct MintParams {
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens minted
    address recipient;
  }

  struct RedeemParams {
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send collateral tokens redeemed
    address recipient;
  }

  struct ExchangeParams {
    // Destination pool
    ISynthereumLiquidityPoolGeneral destPool;
    // Amount of source synthetic tokens that user wants to use for exchanging
    uint256 numTokens;
    // Minimum Amount of destination synthetic tokens that user wants to receive (anti-slippage)
    uint256 minDestNumTokens;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens exchanged
    address recipient;
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata mintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata redeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams calldata exchangeParams)
    external
    returns (uint256 destNumTokensMinted, uint256 feePaid);

  /**
   * @notice Withdraw unused deposited collateral by the LP
   * @notice Only a sender with LP role can call this function
   * @param collateralAmount Collateral to be withdrawn
   * @return remainingLiquidity Remaining unused collateral in the pool
   */
  function withdrawLiquidity(uint256 collateralAmount)
    external
    returns (uint256 remainingLiquidity);

  /**
   * @notice Increase collaterallization of Lp position
   * @notice Only a sender with LP role can call this function
   * @param collateralToTransfer Collateral to be transferred before increase collateral in the position
   * @param collateralToIncrease Collateral to be added to the position
   * @return newTotalCollateral New total collateral amount
   */
  function increaseCollateral(
    uint256 collateralToTransfer,
    uint256 collateralToIncrease
  ) external returns (uint256 newTotalCollateral);

  /**
   * @notice Decrease collaterallization of Lp position
   * @notice Check that final poosition is not undercollateralized
   * @notice Only a sender with LP role can call this function
   * @param collateralToDecrease Collateral to decreased from the position
   * @param collateralToWithdraw Collateral to be transferred to the LP
   * @return newTotalCollateral New total collateral amount
   */
  function decreaseCollateral(
    uint256 collateralToDecrease,
    uint256 collateralToWithdraw
  ) external returns (uint256 newTotalCollateral);

  /**
   * @notice Withdraw fees gained by the sender
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee() external returns (uint256 feeClaimed);

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return synthTokensLiquidated Amount of synthetic tokens liquidated
   * @return collateralReceived Amount of received collateral equal to the value of tokens liquidated
   * @return rewardAmount Amount of received collateral as reward for the liquidation
   */
  function liquidate(uint256 numSynthTokens)
    external
    returns (
      uint256 synthTokensLiquidated,
      uint256 collateralReceived,
      uint256 rewardAmount
    );

  /**
   * @notice Redeem tokens after emergency shutdown
   * @return synthTokensSettled Amount of synthetic tokens liquidated
   * @return collateralSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown()
    external
    returns (uint256 synthTokensSettled, uint256 collateralSettled);

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @notice Only the maintainer can call this function
   * @param _feeData Fee info (percentage + recipients + weigths)
   */
  function setFee(ISynthereumLiquidityPoolStorage.FeeData calldata _feeData)
    external;

  /**
   * @notice Update the fee percentage
   * @notice Only the maintainer can call this function
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage) external;

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @notice Only the maintainer can call this function
   * @param feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata feeRecipients,
    uint32[] calldata feeProportions
  ) external;

  /**
   * @notice Update the overcollateralization percentage
   * @notice Only the maintainer can call this function
   * @param _overCollateralization Overcollateralization percentage
   */
  function setOverCollateralization(uint256 _overCollateralization) external;

  /**
   * @notice Update the liquidation reward percentage
   * @notice Only the maintainer can call this function
   * @param _liquidationReward Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationReward(uint256 _liquidationReward) external;

  /**
   * @notice Returns fee percentage set by the maintainer
   * @return Fee percentage
   */
  function feePercentage() external view returns (uint256);

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigths
   */
  function feeRecipientsInfo()
    external
    view
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    );

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return Number of synthetic tokens
   */
  function totalSyntheticTokens() external view returns (uint256);

  /**
   * @notice Returns the total amount of collateral used for collateralizing tokens (users + LP)
   * @return Total collateral amount
   */
  function totalCollateralAmount() external view returns (uint256);

  /**
   * @notice Returns the total amount of fees to be withdrawn
   * @return Total fee amount
   */
  function totalFeeAmount() external view returns (uint256);

  /**
   * @notice Returns the user's fee to be withdrawn
   * @param user User's address
   * @return User's fee
   */
  function userFee(address user) external view returns (uint256);

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return Percentage of overcollateralization
   */
  function collateralRequirement() external view returns (uint256);

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return Percentage of reward
   */
  function liquidationReward() external view returns (uint256);

  /**
   * @notice Returns the price of the pair at the moment of the shutdown
   * @return Price of the pair
   */
  function emergencyShutdownPrice() external view returns (uint256);

  /**
   * @notice Returns the timestamp (unix time) at the moment of the shutdown
   * @return Timestamp
   */
  function emergencyShutdownTimestamp() external view returns (uint256);

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage() external returns (bool, uint256);

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param inputCollateral Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(uint256 inputCollateral)
    external
    view
    returns (uint256 synthTokensReceived, uint256 feePaid);

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(uint256 syntheticTokens)
    external
    view
    returns (uint256 collateralAmountReceived, uint256 feePaid);

  /**
   * @notice Returns the destination synthetic tokens amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @param  destinationPool Pool in which mint the destination synthetic token
   * @return destSyntheticTokensReceived Synthetic tokens will be received from destination pool
   * @return feePaid Collateral fee will be paid
   */
  function getExchangeTradeInfo(
    uint256 syntheticTokens,
    ISynthereumLiquidityPoolGeneral destinationPool
  )
    external
    view
    returns (uint256 destSyntheticTokensReceived, uint256 feePaid);
}