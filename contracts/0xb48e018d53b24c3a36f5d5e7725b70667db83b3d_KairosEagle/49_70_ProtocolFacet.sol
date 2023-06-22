// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IProtocolFacet} from "./interface/IProtocolFacet.sol";

import {Loan, Protocol} from "./DataStructure/Storage.sol";
import {protocolStorage} from "./DataStructure/Global.sol";
import {Ray} from "./DataStructure/Objects.sol";

/// @notice external loupe functions exposing protocol storage
contract ProtocolFacet is IProtocolFacet {
    /// @notice gets the rate of tranche `id`
    /// @param id rate identifier
    /// @return rate the rate of the tranche, as a Ray, multiplier per second of the amount to repay (non compounding)
    ///         I.e lent * time since loan start * tranche = interests to repay
    function getRateOfTranche(uint256 id) external view returns (Ray rate) {
        return protocolStorage().tranche[id];
    }

    /// @notice gets current values of parameters impacting loans behavior and total number of loans (active and ended)
    /// @return auctionPriceFactor factor multiplied with the loan to value of a loan to get initial price
    ///         of a collateral on sale
    /// @return auctionDuration number of seconds after the auction start when the price hits 0
    /// @return nbOfLoans total number of loans ever issued (active and ended)
    /// @return nbOfTranches total number of interest rates tranches ever created (active and inactive)
    function getParameters()
        external
        view
        returns (Ray auctionPriceFactor, uint256 auctionDuration, uint256 nbOfLoans, uint256 nbOfTranches)
    {
        Protocol storage proto = protocolStorage();
        auctionPriceFactor = proto.auction.priceFactor;
        auctionDuration = proto.auction.duration;
        nbOfLoans = proto.nbOfLoans;
        nbOfTranches = proto.nbOfTranches;
    }

    /// @notice get loan metadata
    /// @param id loan identifier
    /// @return loan the corresponding loan
    function getLoan(uint256 id) external view returns (Loan memory) {
        return protocolStorage().loan[id];
    }

    /// @notice get the minimal amount to repay per offer used in loan and minimum amount to borrow per offer.
    ///     Gives currently active settings, may not concern loans already issued.
    /// @param currency the erc20 asset lent on which the parameters apply
    /// @return minOfferCost the minimal amount to repay per offer used in loan
    /// @return offerBorrowAmountLowerBound  minimum amount to borrow per offer used in loan
    function getMinOfferCostAndBorrowableAmount(
        IERC20 currency
    ) external view returns (uint256 minOfferCost, uint256 offerBorrowAmountLowerBound) {
        Protocol storage proto = protocolStorage();
        minOfferCost = proto.minOfferCost[currency];
        offerBorrowAmountLowerBound = proto.offerBorrowAmountLowerBound[currency];
    }
}