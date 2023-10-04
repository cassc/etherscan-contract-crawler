// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOfferController } from "./IOfferController.sol";

import { OfferAuth, LoanOffer, BorrowOffer, LoanOfferInput, LoanFullfillment, BorrowOfferInput, BorrowFullfillment, RepayFullfillment, RefinanceFullfillment, Lien, LienPointer } from "../lib/Structs.sol";

interface IKettle is IOfferController {
    event Repay(uint256 lienId, address collection, uint256 amount);

    event Seize(uint256 lienId, address collection);

    event Refinance(
        uint256 lienId,
        address collection,
        address currency,
        uint256 amount,
        address oldLender,
        address newLender,
        uint256 oldBorrowAmount,
        uint256 newBorrowAmount,
        uint256 oldRate,
        uint256 newRate
    );

    function liens(uint256 lienId) external view returns (bytes32 lienHash);

    function getRepaymentAmount(
        uint256 borrowAmount,
        uint256 rate,
        uint256 duration
    ) external returns (uint256 repayAmount);

    /*//////////////////////////////////////////////////
                    BORROW FLOWS
    //////////////////////////////////////////////////*/
    function borrow(
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        uint256 loanAmount,
        uint256 collateralTokenId,
        address borrower,
        bytes32[] calldata proof
    ) external returns (uint256 lienId);

    function borrowBatch(
        LoanOfferInput[] calldata loanOffers,
        LoanFullfillment[] calldata fullfillments,
        address borrower
    ) external returns (uint256[] memory lienIds);

    /*//////////////////////////////////////////////////
                    LOAN FLOWS
    //////////////////////////////////////////////////*/
    function loan(
        BorrowOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature
    ) external returns (uint256 lienId);

    function loanBatch(
        BorrowOfferInput[] calldata borrowOffers,
        BorrowFullfillment[] calldata fullfillments
    ) external returns (uint256[] memory lienIds);

    /*//////////////////////////////////////////////////
                      REPAYMENT FLOWS
    //////////////////////////////////////////////////*/
    function repay(Lien calldata lien, uint256 lienId) external;

    function repayBatch(RepayFullfillment[] calldata repayments) external;

    /*//////////////////////////////////////////////////
                    REFINANCING FLOWS
    //////////////////////////////////////////////////*/
    function refinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        bytes32[] calldata proof
    ) external;
    
    function refinanceBatch(
        LoanOfferInput[] calldata loanOffers,
        RefinanceFullfillment[] calldata fullfillments
    ) external;

    /*//////////////////////////////////////////////////
                    SEIZE FLOWS
    //////////////////////////////////////////////////*/
    function seize(LienPointer[] calldata lienPointers) external;
}