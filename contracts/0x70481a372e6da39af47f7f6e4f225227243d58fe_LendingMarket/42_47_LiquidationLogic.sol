// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {DataTypes} from "../types/DataTypes.sol";
import {PercentageMath} from "../utils/PercentageMath.sol";
import {IAddressProvider} from "../../interfaces/IAddressProvider.sol";
import {IFeeDistributor} from "../../interfaces/IFeeDistributor.sol";
import {ILoanCenter} from "../../interfaces/ILoanCenter.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {ITokenOracle} from "../../interfaces/ITokenOracle.sol";
import {IGenesisNFT} from "../../interfaces/IGenesisNFT.sol";
import {INFTOracle} from "../../interfaces/INFTOracle.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title LiquidationLogic
/// @author leNFT
/// @notice Contains the logic for the liquidate function
/// @dev Library dealing with the logic for the function responsible for liquidating a loan
library LiquidationLogic {
    uint256 private constant LIQUIDATION_AUCTION_PERIOD = 3600 * 24;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Liquidates a loan
    /// @param addressProvider The address of the addresses provider
    /// @param params A struct with the parameters of the liquidate function
    function createLiquidationAuction(
        IAddressProvider addressProvider,
        DataTypes.CreateAuctionParams memory params
    ) external {
        // Get loan center
        ILoanCenter loanCenter = ILoanCenter(addressProvider.getLoanCenter());
        // Get the loan
        DataTypes.LoanData memory loanData = loanCenter.getLoan(params.loanId);

        // Validate the auction creation
        _validateCreateLiquidationAuction(
            addressProvider,
            address(loanCenter),
            params,
            loanData.state,
            loanData.pool,
            loanData.nftAsset,
            loanData.nftTokenIds
        );

        // Add auction to the loan
        loanCenter.auctionLoan(params.loanId, params.onBehalfOf, params.bid);

        // Get the payment from the caller
        IERC20Upgradeable(IERC4626(loanData.pool).asset()).safeTransferFrom(
            params.caller,
            address(this),
            params.bid
        );
    }

    /// @notice Bid on a liquidation auction
    /// @param addressProvider The address of the addresses provider
    /// @param params A struct with the parameters of the bid function
    function bidLiquidationAuction(
        IAddressProvider addressProvider,
        DataTypes.BidAuctionParams memory params
    ) external {
        // Get the loan center
        ILoanCenter loanCenter = ILoanCenter(addressProvider.getLoanCenter());
        // Get the loan
        DataTypes.LoanState loanState = loanCenter.getLoanState(params.loanId);
        address loanLendingPool = loanCenter.getLoanLendingPool(params.loanId);
        // Get the loan liquidation data
        DataTypes.LoanLiquidationData memory loanLiquidationData = loanCenter
            .getLoanLiquidationData(params.loanId);

        // validate the auction bid
        _validateBidLiquidationAuction(
            params.bid,
            loanState,
            loanLiquidationData
        );

        // Get the address of this asset's lending pool
        address poolAsset = IERC4626(loanLendingPool).asset();

        // Send the old liquidator their funds back
        IERC20Upgradeable(poolAsset).safeTransfer(
            loanLiquidationData.liquidator,
            loanLiquidationData.auctionMaxBid
        );

        // Update the auction bid
        loanCenter.updateLoanAuctionBid(
            params.loanId,
            params.onBehalfOf,
            params.bid
        );

        // Get the payment from the caller
        IERC20Upgradeable(poolAsset).safeTransferFrom(
            params.caller,
            address(this),
            params.bid
        );
    }

    /// @notice Claim a liquidation auction
    /// @param addressProvider The address of the addresses provider
    /// @param params A struct with the parameters of the claim function
    function claimLiquidation(
        IAddressProvider addressProvider,
        DataTypes.ClaimLiquidationParams memory params
    ) external {
        // Get the loan center
        ILoanCenter loanCenter = ILoanCenter(addressProvider.getLoanCenter());
        // Get the loan
        DataTypes.LoanData memory loanData = loanCenter.getLoan(params.loanId);
        // Get the loan liquidation data
        DataTypes.LoanLiquidationData memory loanLiquidationData = loanCenter
            .getLoanLiquidationData(params.loanId);

        // Validate the auction claim
        _validateClaimLiquidation(
            loanData.state,
            loanLiquidationData.auctionStartTimestamp
        );

        // Get the address of this asset's pool
        address poolAsset = IERC4626(loanData.pool).asset();
        // Repay loan...
        uint256 fundsLeft = loanLiquidationData.auctionMaxBid;
        uint256 loanInterest = loanCenter.getLoanInterest(params.loanId);
        uint256 loanDebt = loanData.amount + loanInterest;
        // If we only have funds to pay back part of the loan
        if (fundsLeft < loanDebt) {
            ILendingPool(loanData.pool).receiveUnderlyingDefaulted(
                address(this),
                fundsLeft,
                uint256(loanData.borrowRate),
                loanData.amount
            );

            fundsLeft = 0;
        }
        // If we have funds to cover the whole debt associated with the loan
        else {
            ILendingPool(loanData.pool).receiveUnderlying(
                address(this),
                loanData.amount,
                uint256(loanData.borrowRate),
                loanInterest
            );

            fundsLeft -= loanDebt;
        }

        // ... then get the protocol liquidation fee (if there are still funds available) ...
        if (fundsLeft > 0) {
            // Get the protocol fee
            uint256 protocolFee = PercentageMath.percentMul(
                loanLiquidationData.auctionMaxBid,
                ILendingPool(loanData.pool).getPoolConfig().liquidationFeeRate
            );
            // If the protocol fee is higher than the amount we have left, set the protocol fee to the amount we have left
            if (protocolFee > fundsLeft) {
                protocolFee = fundsLeft;
            }
            // Send the protocol fee to the fee distributor contract
            IERC20Upgradeable(poolAsset).safeTransfer(
                addressProvider.getFeeDistributor(),
                protocolFee
            );
            // Checkpoint the fee distribution
            IFeeDistributor(addressProvider.getFeeDistributor()).checkpoint(
                poolAsset
            );
            // Subtract the protocol fee from the funds left
            fundsLeft -= protocolFee;
        }

        // ... and the rest to the borrower.
        if (fundsLeft > 0) {
            IERC20Upgradeable(poolAsset).safeTransfer(
                loanData.owner,
                fundsLeft
            );
        }

        // Update the state of the loan
        loanCenter.liquidateLoan(params.loanId);

        // Send collateral to liquidator
        for (uint i = 0; i < loanData.nftTokenIds.length; i++) {
            IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
                address(this),
                loanLiquidationData.liquidator,
                loanData.nftTokenIds[i]
            );
        }

        // Unlock Genesis NFT if it was used with this loan
        if (loanData.genesisNFTId != 0) {
            // Unlock Genesis NFT
            IGenesisNFT(addressProvider.getGenesisNFT()).unlockGenesisNFT(
                uint256(loanData.genesisNFTId)
            );
        }
    }

    /// @notice Validate the parameters of the create liquidation auction function
    /// @param addressProvider The address of the addresses provider
    /// @param loanCenter The loan center
    /// @param params A struct with the parameters of the create liquidation auction function
    /// @param loanState The state of the loan
    /// @param lendingPool The address of the lending pool
    /// @param loanNFTAsset The address of the loan NFT asset
    /// @param loanNFTTokenIds The token ids of the loan NFT
    function _validateCreateLiquidationAuction(
        IAddressProvider addressProvider,
        address loanCenter,
        DataTypes.CreateAuctionParams memory params,
        DataTypes.LoanState loanState,
        address lendingPool,
        address loanNFTAsset,
        uint256[] memory loanNFTTokenIds
    ) internal view {
        // Verify if liquidation conditions are met
        //Require the loan exists
        require(
            loanState == DataTypes.LoanState.Active,
            "VL:VCLA:LOAN_NOT_FOUND"
        );

        // Check if collateral / debt relation allows for liquidation
        (uint256 ethPrice, uint256 precision) = ITokenOracle(
            addressProvider.getTokenOracle()
        ).getTokenETHPrice(IERC4626(lendingPool).asset());

        uint256 collateralETHPrice = INFTOracle(addressProvider.getNFTOracle())
            .getTokensETHPrice(
                loanNFTAsset,
                loanNFTTokenIds,
                params.request,
                params.packet
            );

        require(
            (ILoanCenter(loanCenter).getLoanMaxDebt(
                params.loanId,
                collateralETHPrice
            ) * precision) /
                ethPrice <
                ILoanCenter(loanCenter).getLoanDebt(params.loanId),
            "VL:VCLA:MAX_DEBT_NOT_EXCEEDED"
        );

        // Check if bid is large enough
        require(
            (ethPrice * params.bid) / precision >=
                PercentageMath.percentMul(
                    collateralETHPrice,
                    (PercentageMath.PERCENTAGE_FACTOR -
                        ILendingPool(lendingPool)
                            .getPoolConfig()
                            .maxLiquidatorDiscount)
                ),
            "VL:VCLA:BID_TOO_LOW"
        );
    }

    /// @notice Validate the parameters of the bid liquidation auction function
    /// @param currentBid The current bid of the auction
    /// @param loanState The state of the loan
    /// @param loanLiquidationData The liquidation data of the loan
    function _validateBidLiquidationAuction(
        uint256 currentBid,
        DataTypes.LoanState loanState,
        DataTypes.LoanLiquidationData memory loanLiquidationData
    ) internal view {
        // Check if the auction exists
        require(
            loanState == DataTypes.LoanState.Auctioned,
            "VL:VBLA:AUCTION_NOT_FOUND"
        );

        // Check if the auction is still active
        require(
            block.timestamp <
                loanLiquidationData.auctionStartTimestamp +
                    LIQUIDATION_AUCTION_PERIOD,
            "VL:VBLA:AUCTION_NOT_ACTIVE"
        );

        // Check if bid is higher than current bid
        require(
            currentBid > loanLiquidationData.auctionMaxBid,
            "VL:VBLA:BID_TOO_LOW"
        );
    }

    function _validateClaimLiquidation(
        DataTypes.LoanState loanState,
        uint256 loanAuctionStartTimestamp
    ) internal view {
        // Check if the loan is being auctioned
        require(
            loanState == DataTypes.LoanState.Auctioned,
            "VL:VCLA:AUCTION_NOT_FOUND"
        );

        // Check if the auction is still active
        require(
            block.timestamp >
                loanAuctionStartTimestamp + LIQUIDATION_AUCTION_PERIOD,
            "VL:VCLA:AUCTION_NOT_FINISHED"
        );
    }
}