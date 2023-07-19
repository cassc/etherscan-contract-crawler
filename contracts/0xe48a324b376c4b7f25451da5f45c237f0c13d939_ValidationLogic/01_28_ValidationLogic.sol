// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../../interfaces/ILendPool.sol";
import {IUToken} from "../../interfaces/IUToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ValidationLogic library
 * @author BendDao; Forked and edited by Unlockd
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;
  /*//////////////////////////////////////////////////////////////
                          STRUCTS
  //////////////////////////////////////////////////////////////*/
  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 currentLiquidationThreshold;
    uint256 amountOfCollateralNeeded;
    uint256 userCollateralBalance;
    uint256 userBorrowBalance;
    uint256 availableLiquidity;
    uint256 healthFactor;
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
    bool stableRateBorrowingEnabled;
    bool nftIsActive;
    bool nftIsFrozen;
    address loanReserveAsset;
    address loanBorrower;
  }

  /*//////////////////////////////////////////////////////////////
                          MAIN LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Validates a deposit action
   * @param reserve The reserve object on which the user is depositing
   * @param amount The amount to be deposited
   */
  function validateDeposit(DataTypes.ReserveData storage reserve, uint256 amount) external view {
    (bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);
  }

  /**
   * @dev Validates a withdraw action
   * @param reserveData The reserve state
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   */
  function validateWithdraw(
    DataTypes.ReserveData storage reserveData,
    uint256 amount,
    uint256 userBalance,
    address uToken
  ) external view {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , ) = reserveData.configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

    // Case where there is not enough liquidity to cover user's withdrawal
    uint256 availableLiquidity = IUToken(uToken).getAvailableLiquidity();
    require(amount <= availableLiquidity, Errors.LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY);
  }

  /**
   * @dev Validates a borrow action
   * @param reserveData The reserve state from which the user is borrowing
   * @param nftData The state of the user for the specific nft
   */
  function validateBorrow(
    DataTypes.ExecuteBorrowParams memory params,
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    address loanAddress,
    uint256 loanId,
    address reserveOracle,
    address nftOracle
  ) external view {
    ValidateBorrowLocalVars memory vars;
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(params.amount > 0, Errors.VL_INVALID_AMOUNT);

    if (loanId != 0) {
      DataTypes.LoanData memory loanData = ILendPoolLoan(loanAddress).getLoan(loanId);

      require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
      require(params.asset == loanData.reserveAsset, Errors.VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER);
      require(params.onBehalfOf == loanData.borrower, Errors.VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER);
    }

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.stableRateBorrowingEnabled) = reserveData
      .configuration
      .getFlags();
    require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
    require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);
    (vars.nftIsActive, vars.nftIsFrozen) = nftData.configuration.getFlags();
    require(vars.nftIsActive, Errors.VL_NO_ACTIVE_NFT);
    require(!vars.nftIsFrozen, Errors.VL_NFT_FROZEN);

    /**
     * @dev additional check for individual asset
     */
    (vars.nftIsActive, vars.nftIsFrozen) = nftConfig.getFlags();
    require(vars.nftIsActive, Errors.VL_NO_ACTIVE_NFT);
    require(!vars.nftIsFrozen, Errors.VL_NFT_FROZEN);

    require(
      (nftConfig.getConfigTimestamp() + ILendPool(address(this)).getTimeframe()) >= block.timestamp,
      Errors.VL_TIMEFRAME_EXCEEDED
    );

    (vars.currentLtv, vars.currentLiquidationThreshold, ) = nftConfig.getCollateralParams();

    (vars.userCollateralBalance, vars.userBorrowBalance, vars.healthFactor) = GenericLogic.calculateLoanData(
      params.asset,
      reserveData,
      params.nftAsset,
      params.nftTokenId,
      nftConfig,
      loanAddress,
      loanId,
      reserveOracle,
      nftOracle
    );

    require(vars.userCollateralBalance != 0, Errors.VL_COLLATERAL_BALANCE_IS_0);
    require(
      vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    //LTV is calculated in percentage
    vars.amountOfCollateralNeeded = (vars.userBorrowBalance + params.amount).percentDiv(vars.currentLtv);

    require(vars.amountOfCollateralNeeded <= vars.userCollateralBalance, Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW);
  }

  /**
   * @dev Validates a repay action
   * @param reserveData The reserve state from which the user is repaying
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param borrowAmount The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    uint256 amountSent,
    uint256 borrowAmount
  ) external view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

    require(borrowAmount > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);

    require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
  }

  /**
   * @dev Validates a redeem action
   * @param reserveData The reserve state
   * @param nftData The nft state
   */
  function validateRedeem(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    uint256 amount
  ) external view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(loanData.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    require(amount > 0, Errors.VL_INVALID_AMOUNT);
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNALS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Validates the auction action
   * @param reserveData The reserve data of the principal
   * @param nftData The nft data of the underlying nft
   * @param bidPrice Total variable debt balance of the user
   **/
  function validateAuction(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    uint256 bidPrice
  ) internal view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(
      loanData.state == DataTypes.LoanState.Active || loanData.state == DataTypes.LoanState.Auction,
      Errors.LPL_INVALID_LOAN_STATE
    );

    require(bidPrice > 0, Errors.VL_INVALID_AMOUNT);
  }

  /**
   * @dev Validates the liquidation action
   * @param reserveData The reserve data of the principal
   * @param nftData The data of the underlying NFT
   * @param loanData The loan data of the underlying NFT
   **/
  function validateBuyout(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData
  ) internal view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(
      loanData.state == DataTypes.LoanState.Active || loanData.state == DataTypes.LoanState.Auction,
      Errors.LPL_INVALID_LOAN_STATE
    );
  }

  /**
   * @dev Validates the liquidation action
   * @param reserveData The reserve data of the principal
   * @param nftData The data of the underlying NFT
   * @param loanData The loan data of the underlying NFT
   **/
  function validateLiquidate(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData
  ) internal view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(loanData.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);
  }

  /**
   * @dev Validates an uToken transfer
   * @param from The user from which the uTokens are being transferred
   * @param reserveData The state of the reserve
   */
  function validateTransfer(address from, DataTypes.ReserveData storage reserveData) internal pure {
    from;
    reserveData;
  }
}