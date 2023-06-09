// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBorrowHandlers} from "../interface/IBorrowHandlers.sol";

import {BorrowCheckers} from "./BorrowCheckers.sol";
import {CollateralState, NFToken, OfferArg, Ray} from "../DataStructure/Objects.sol";
import {Loan, Payment, Protocol, Provision, Auction} from "../DataStructure/Storage.sol";
import {ONE, protocolStorage, supplyPositionStorage} from "../DataStructure/Global.sol";
import {RayMath} from "../utils/RayMath.sol";
import {Erc20CheckedTransfer} from "../utils/Erc20CheckedTransfer.sol";
import {SafeMint} from "../SupplyPositionLogic/SafeMint.sol";
// solhint-disable-next-line max-line-length
import {RequestedAmountTooHigh, UnsafeAmountLent, MultipleOffersUsed, ShareMatchedIsTooLow} from "../DataStructure/Errors.sol";

/// @notice handles usage of entities to borrow with
abstract contract BorrowHandlers is IBorrowHandlers, BorrowCheckers, SafeMint {
    using RayMath for uint256;
    using RayMath for Ray;
    using Erc20CheckedTransfer for IERC20;

    Ray private immutable minShareLent;

    constructor() {
        /* see testWorstCaseEstimatedValue() in RayMath.t.sol for the test showing worst case considered values
        in the return value calculation of AuctionFacet.sol's price(uint256 loanId) method */
        minShareLent = ONE.div(100_000_000);
    }

    /// @notice handles usage of a loan offer to borrow from
    /// @param arg arguments for the usage of this offer
    /// @param collatState tracked state of the matching of the collateral
    /// @return collateralState updated `collatState` after usage of the offer
    function useOffer(
        OfferArg memory arg,
        CollateralState memory collatState
    ) internal view returns (CollateralState memory, address /* signer */) {
        address signer = checkOfferArg(arg);
        Ray shareMatched;

        checkCollateral(arg.offer, collatState.nft);

        // we keep track of the share of the maximum value (`loanToValue`) proposed by an offer used by the borrower.
        shareMatched = arg.amount.div(arg.offer.loanToValue);

        // a 0 share or too low can lead to DOS, cf https://github.com/sherlock-audit/2023-02-kairos-judging/issues/76
        if (shareMatched.lt(minShareLent)) {
            revert ShareMatchedIsTooLow(arg.offer, arg.amount);
        }

        collatState.matched = collatState.matched.add(shareMatched);

        /* we consider that lenders are acquiring shares of the NFT used as collateral by lending the amount
        corresponding to shareMatched. We check this process is not ditributing more shares than the full NFT value. */
        if (collatState.matched.gt(ONE)) {
            revert RequestedAmountTooHigh(
                arg.amount,
                arg.offer.loanToValue.mul(ONE.sub(collatState.matched.sub(shareMatched))),
                arg.offer
            );
        }

        return (collatState, signer);
    }

    /// @notice handles usage of one collateral to back a loan request
    /// @param args arguments for usage of one or multiple loan offers
    /// @param from borrower for this loan
    /// @param nft collateral to use
    /// @return loan the loan created backed by provided collateral
    function useCollateral(
        OfferArg[] memory args,
        address from,
        NFToken memory nft
    ) internal returns (Loan memory loan) {
        address signer;
        CollateralState memory collatState = initializedCollateralState(args[0], from, nft);

        /* following the sherlock audit, we found some possible manipulations in multi offers loans. This condition is
        change-minimized prevention to this, keeping the code as close to the reviewed version as possible. An optimized
        Kairos Loan v2 will soon be published. */
        if (args.length > 1) {
            revert MultipleOffersUsed();
        }

        (collatState, signer) = useOffer(args[0], collatState);
        uint256 lent = args[0].amount;

        // cf RepayFacet for the rationale of this check. We prevent repaying being impossible due to an overflow in the
        // interests to repay calculation.
        if (lent > 1e40) {
            revert UnsafeAmountLent(lent);
        }
        loan = initializedLoan(collatState, from, nft, lent);
        protocolStorage().loan[collatState.loanId] = loan;

        // transferring the borrowed funds from the lender to the borrower
        collatState.assetLent.checkedTransferFrom(signer, collatState.from, lent);

        /* issuing supply position NFT to the signer of the loan offer with metadatas
        The only position of the loan is not minted in useOffer but in the end of this functions as a way to better
        follow the checks-effects-interactions pattern as it includes an external call, to prevent unforseen
        consequences of a reentrency. */
        safeMint(signer, Provision({amount: lent, share: collatState.matched, loanId: collatState.loanId}));

        emit Borrow(collatState.loanId, abi.encode(loan));
    }

    /// @notice initializes the collateral state memory struct used to keep track of the collateralization and other
    ///     health checks variables during the issuance of a loan
    /// @param firstOfferArg the first struct of arguments for an offer among potentially multiple used loan offers
    /// @param from I.e borrower
    /// @param nft - used as collateral
    /// @return collatState the initialized collateral state struct
    function initializedCollateralState(
        OfferArg memory firstOfferArg,
        address from,
        NFToken memory nft
    ) internal returns (CollateralState memory) {
        return
            CollateralState({
                matched: Ray.wrap(0),
                assetLent: firstOfferArg.offer.assetToLend,
                tranche: firstOfferArg.offer.tranche,
                minOfferDuration: firstOfferArg.offer.duration,
                minOfferLoanToValue: firstOfferArg.offer.loanToValue,
                maxOfferLoanToValue: firstOfferArg.offer.loanToValue,
                from: from,
                nft: nft,
                loanId: ++protocolStorage().nbOfLoans // returns incremented value (also increments in storage)
            });
    }

    /// @notice initializes the loan struct representing borrowed funds from one NFT collateral, will be stored
    /// @param collatState contains info on share of the collateral value used by the borrower
    /// @param nft - used as collateral
    /// @param lent amount lent/borrowed
    /// @return loan tne initialized loan to store
    function initializedLoan(
        CollateralState memory collatState,
        address from,
        NFToken memory nft,
        uint256 lent
    ) internal view returns (Loan memory) {
        Protocol storage proto = protocolStorage();

        /* the shortest offered duration determines the max date of repayment to make sure all loan offer terms are
        respected */
        uint256 endDate = block.timestamp + collatState.minOfferDuration;
        Payment memory notPaid; // not paid as it corresponds to the meaning of the uninitialized struct

        /* the minimum interests amount to repay is used as anti ddos mechanism to prevent borrowers to produce lots of
        dust supply positions that the lenders will have to pay gas to claim. as each position can be used to claim
        funds separetely and induce a gas cost. With a design approach similar to the auction parameters setting,
        this minimal cost is set at borrow time to avoid bad surprises arising from governance setting new parameters
        during the loan life. cf docs for more details. */
        notPaid.minInterestsToRepay = proto.minOfferCost[collatState.assetLent];

        return
            Loan({
                assetLent: collatState.assetLent,
                lent: lent,
                shareLent: collatState.matched,
                startDate: block.timestamp,
                endDate: endDate,
                /* auction parameters are copied from protocol parameters to the loan storage as a way to prevent
                a governance-initiated change of terms to modify the terms a borrower chose to accept or change the
                price of an NFT being sold abruptly during the course of an auction. */
                auction: Auction({duration: proto.auction.duration, priceFactor: proto.auction.priceFactor}),
                /* the interest rate is stored as a value instead of the tranche id as a precaution in case of a change
                in the interest rate mechanisms due to contract upgrade */
                interestPerSecond: proto.tranche[collatState.tranche],
                borrower: from,
                collateral: nft,
                payment: notPaid
            });
    }
}