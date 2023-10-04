// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { Helpers } from "./Helpers.sol";
import { CollateralVerifier } from "./CollateralVerifier.sol";
import { SafeTransfer } from "./SafeTransfer.sol";

import { OfferController } from "./OfferController.sol";
import { IKettle } from "./interfaces/IKettle.sol";

import { CollateralType, Fee, Lien, LoanOffer, BorrowOffer, LoanOfferInput, BorrowOfferInput, LienPointer, LoanFullfillment, BorrowFullfillment, RepayFullfillment, RefinanceFullfillment, OfferAuth } from "./lib/Structs.sol";

import { InvalidLien, Unauthorized, LienIsDefaulted, LienNotDefaulted, CollectionsDoNotMatch, CurrenciesDoNotMatch, NoEscrowImplementation, InvalidCollateralAmount, InvalidCollateralType, TotalFeeTooHigh } from "./lib/Errors.sol";

contract Kettle is IKettle, Ownable, OfferController, SafeTransfer, ERC721Holder, ERC1155Holder {
    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _LIQUIDATION_THRESHOLD = 100_000;
    uint256 private _nextLienId;

    mapping(uint256 => bytes32) public liens;
    mapping(address => address) public escrows;

    constructor(address authSigner) OfferController(authSigner) { }

    /*//////////////////////////////////////////////////
                       GETTERS
    //////////////////////////////////////////////////*/
    function getRepaymentAmount(
        uint256 borrowAmount,
        uint256 rate,
        uint256 duration
    ) public pure returns (uint256) {
        return Helpers.computeCurrentDebt(borrowAmount, rate, duration);
    }

    function getEscrow(
        address collection
    ) public view returns (address escrow) {
        escrow = escrows[collection];
        if (escrow == address(0)) {
            return address(this);
        }
    }

    /*//////////////////////////////////////////////////
                       SETTERS
    //////////////////////////////////////////////////*/
    function setEscrow(address collection, address escrow) external onlyOwner {
        escrows[collection] = escrow;
    }

    /*//////////////////////////////////////////////////
                    FEE FLOWS
    //////////////////////////////////////////////////*/
    function payFees(
        address currency,
        address lender,
        uint256 loanAmount,
        Fee[] calldata fees
    ) internal returns (uint256 totalFees) {

        totalFees = 0;
        for (uint256 i = 0; i < fees.length; i++) {
            uint256 feeAmount = Helpers.computeFeeAmount(
                loanAmount,
                fees[i].rate
            );

            SafeTransfer.transferERC20(
                currency, 
                lender, 
                fees[i].recipient, 
                feeAmount
            );

            unchecked {
                totalFees += feeAmount;
            }
        }

        // revert if total fees are more than loan amount (over 100% fees)
        if (totalFees >= loanAmount) {
            revert TotalFeeTooHigh();
        }
    }

    /*//////////////////////////////////////////////////
                    BORROW FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Verifies and starts multiple liens against loan offers; then transfers loan and collateral assets
     * @param loanOffers Loan offers
     * @param fullfillments Loan offer fullfillments
     * @param borrower address of borrower (optional)
     * @return lienIds array of lienIds
     */
    function borrowBatch(
        LoanOfferInput[] calldata loanOffers,
        LoanFullfillment[] calldata fullfillments,
        address borrower
    ) external returns (uint256[] memory lienIds) {
        uint256 numFills = fullfillments.length;
        lienIds = new uint256[](numFills);

        for (uint256 i = 0; i < numFills; i++) {
            LoanFullfillment calldata fullfillment = fullfillments[i];
            LoanOfferInput calldata offer = loanOffers[fullfillment.offerIndex];

            lienIds[i] = borrow(
                offer.offer,
                fullfillment.auth,
                offer.offerSignature,
                fullfillment.authSignature,
                fullfillment.loanAmount,
                fullfillment.collateralIdentifier,
                borrower,
                fullfillment.proof
            );
        }
    }

    /**
     * @notice Verifies and takes loan offer; then transfers loan and collateral assets
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Lender offer signature
     * @param authSignature Auth signer signature
     * @param loanAmount Loan amount in ETH
     * @param collateralTokenId Token id to provide as collateral
     * @param borrower address of borrower
     * @param proof proof for criteria offer
     * @return lienId New lien id
     */
    function borrow(
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        uint256 loanAmount,
        uint256 collateralTokenId,
        address borrower,
        bytes32[] calldata proof
    ) public returns (uint256 lienId) {
        if (borrower == address(0)) {
            borrower = msg.sender;
        }

        CollateralVerifier.verifyCollateral(
            offer.collateralType,
            offer.collateralIdentifier,
            collateralTokenId,
            proof
        );

        lienId = _borrow(
            offer,
            auth,
            offerSignature,
            authSignature,
            loanAmount,
            collateralTokenId,
            borrower
        );

        SafeTransfer.transfer(
            offer.collateralType, 
            offer.collection, 
            msg.sender, 
            getEscrow(offer.collection), 
            collateralTokenId, 
            offer.collateralAmount
        );

        /* Transfer fees from lender */
        uint256 totalFees = payFees(
            offer.currency,
            offer.lender,
            loanAmount,
            offer.fees
        );

        /* Transfer loan amount to borrower. */
        unchecked {
            SafeTransfer.transferERC20(
                offer.currency, 
                offer.lender,
                borrower, 
                loanAmount - totalFees
            );
        }
    }

    /**
     * @notice Verifies and takes loan offer; creates new lien
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Lender offer signature
     * @param authSignature Auth signer signature
     * @param loanAmount Loan amount in ETH
     * @param collateralTokenId Token id to provide as collateral
     * @param borrower address of borrower (optional)
     * @return lienId New lien id
     */
    function _borrow(
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        uint256 loanAmount,
        uint256 collateralTokenId,
        address borrower
    ) internal returns (uint256 lienId) {
        Lien memory lien = Lien({
            lender: offer.lender,
            borrower: borrower,
            collateralType: CollateralVerifier.mapCollateralType(offer.collateralType),
            collection: offer.collection,
            amount: offer.collateralAmount,
            tokenId: collateralTokenId,
            currency: offer.currency,
            borrowAmount: loanAmount,
            startTime: block.timestamp,
            duration: offer.duration,
            rate: offer.rate
        });

        /* Create lien. */
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        /* Take the loan offer. */
        _takeLoanOffer(offer, auth, offerSignature, authSignature, lien, lienId);
    }

    /*//////////////////////////////////////////////////
                    LOAN FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Verifies and starts multiple liens against loan offers; then transfers loan and collateral assets
     * @param borrowOffers Borrow offers
     * @param fullfillments Borrow fullfillments
     * @return lienIds array of lienIds
     */
    function loanBatch(
        BorrowOfferInput[] calldata borrowOffers,
        BorrowFullfillment[] calldata fullfillments
    ) external returns (uint256[] memory lienIds) {
        lienIds = new uint256[](fullfillments.length);

        for (uint256 i = 0; i < fullfillments.length; i++) {
            BorrowFullfillment calldata fullfillment = fullfillments[i];
            BorrowOfferInput calldata offer = borrowOffers[fullfillment.offerIndex];

            lienIds[i] = loan(
                offer.offer,
                fullfillment.auth,
                offer.offerSignature,
                fullfillment.authSignature
            );
        }
    }

    /**
     * @notice Verifies and takes loan offer; then transfers loan and collateral assets
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Lender offer signature
     * @param authSignature Auth signer signature
     * @return lienId New lien id
     */
    function loan(
        BorrowOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature
    ) public returns (uint256 lienId) {

        lienId = _loanToBorrower(
            offer,
            auth,
            offerSignature,
            authSignature
        );

        SafeTransfer.transfer(
            offer.collateralType,
            offer.collection,
            offer.borrower,
            getEscrow(offer.collection),
            offer.collateralIdentifier,
            offer.collateralAmount
        );

        /* Transfer fees from lender */
        uint256 totalFees = payFees(
            offer.currency,
            msg.sender,
            offer.loanAmount,
            offer.fees
        );

        /* Transfer loan amount to borrower. */
        unchecked {
            SafeTransfer.transferERC20(
                offer.currency, 
                msg.sender, 
                offer.borrower, 
                offer.loanAmount - totalFees
            );
        }
    }

    /**
     * @notice Verifies and takes loan offer; creates new lien
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Borrower offer signature
     * @param authSignature Auth signer signature
     * @return lienId New lien id
     */
    function _loanToBorrower(
        BorrowOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature
    ) internal returns (uint256 lienId) {
        Lien memory lien = Lien({
            lender: msg.sender,
            borrower: offer.borrower,
            collateralType: CollateralVerifier.mapCollateralType(offer.collateralType),
            collection: offer.collection,
            amount: offer.collateralAmount,
            tokenId: offer.collateralIdentifier,
            currency: offer.currency,
            borrowAmount: offer.loanAmount,
            startTime: block.timestamp,
            duration: offer.duration,
            rate: offer.rate
        });

        /* Create lien. */
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        /* Take the loan offer. */
        _takeBorrowOffer(offer, auth, offerSignature, authSignature, lien, lienId);
    }

    /*//////////////////////////////////////////////////
                    REPAY FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Repays loans in batch
     * @param repayments Loan repayments
     */
    function repayBatch(
        RepayFullfillment[] calldata repayments
    ) external validateLiens(repayments) liensAreActive(repayments) {
        for (uint256 i = 0; i < repayments.length; i++) {
            RepayFullfillment calldata repayment = repayments[i];
            repay(repayment.lien, repayment.lienId);
        }
    }

    /**
     * @notice Repays loan and retrieves collateral
     * @param lien Lien preimage
     * @param lienId Lien id
     */
    function repay(
        Lien calldata lien,
        uint256 lienId
    ) public validateLien(lien, lienId) lienIsActive(lien) {
        uint256 _repayAmount = _repay(lien, lienId);

        SafeTransfer.transfer(
            lien.collateralType,
            lien.collection,
            getEscrow(lien.collection),
            lien.borrower,
            lien.tokenId,
            lien.amount
        );

        SafeTransfer.transferERC20(
            lien.currency,
            msg.sender, 
            lien.lender, 
            _repayAmount
        );
    }

    /**
     * @notice Computes the current debt repayment and burns the lien
     * @dev Does not transfer assets
     * @param lien Lien preimage
     * @param lienId Lien id
     * @return repayAmount Current amount of debt owed on the lien
     */
    function _repay(
        Lien calldata lien,
        uint256 lienId
    ) internal returns (uint256 repayAmount) {
        repayAmount = getRepaymentAmount(
            lien.borrowAmount,
            lien.rate,
            lien.duration
        );

        delete liens[lienId];

        emit Repay(lienId, lien.collection, repayAmount);
    }

    /*//////////////////////////////////////////////////
                    REFINANCE FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Refinances multiple liens with new loan offers;
     * @param loanOffers Loan offers
     * @param fullfillments Loan offer fullfillments
     */
    function refinanceBatch(
        LoanOfferInput[] calldata loanOffers,
        RefinanceFullfillment[] calldata fullfillments
    ) external {
        for (uint256 i = 0; i < fullfillments.length; i++) {
            RefinanceFullfillment calldata fullfillment = fullfillments[i];
            LoanOfferInput calldata offer = loanOffers[fullfillment.offerIndex];

            refinance(
                fullfillment.lien,
                fullfillment.lienId,
                fullfillment.loanAmount,
                offer.offer,
                fullfillment.auth,
                offer.offerSignature,
                fullfillment.authSignature,
                fullfillment.proof
            );
        }
    }

    /**
     * @notice Refinance and existing lien with new loan offer
     * @param lien Existing lien
     * @param lienId Identifier of existing lien
     * @param loanAmount Loan amount in ETH
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Lender offer signature
     * @param authSignature Auth signer signature
     * @param proof proof for criteria offer
     */
    function refinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        bytes32[] calldata proof
    ) public validateLien(lien, lienId) lienIsActive(lien) {
        if (msg.sender != lien.borrower) {
            revert Unauthorized();
        }

        /** 
         * Verify collateral is takeable by loan offer 
         * use token id from lien against collateral identifier of offer
         * make sure the offer is specifying collateral that matches
         * the current lien
         */
        CollateralVerifier.verifyCollateral(
            offer.collateralType,
            offer.collateralIdentifier,
            lien.tokenId,
            proof
        );

        /* Refinance initial loan to new loan (loanAmount must be within lender range) */
        _refinance(lien, lienId, loanAmount, offer, auth, offerSignature, authSignature);

        uint256 repayAmount = getRepaymentAmount(
            lien.borrowAmount,
            lien.rate,
            lien.duration
        );

        /* Transfer fees */
        uint256 totalFees = payFees(
            offer.currency,
            offer.lender,
            loanAmount,
            offer.fees
        );
        unchecked {
            loanAmount -= totalFees;
        }

        if (loanAmount >= repayAmount) {
            /* If new loan is more than the previous, repay the initial loan and send the remaining to the borrower. */
            SafeTransfer.transferERC20(offer.currency, offer.lender, lien.lender, repayAmount);
            unchecked {
                SafeTransfer.transferERC20(offer.currency, offer.lender, lien.borrower, loanAmount - repayAmount);
            }
        } else {
            /* If new loan is less than the previous, borrower must supply the difference to repay the initial loan. */
            SafeTransfer.transferERC20(offer.currency, offer.lender, lien.lender, loanAmount);
            unchecked {
                SafeTransfer.transferERC20(offer.currency, lien.borrower, lien.lender, repayAmount - loanAmount);
            }
        }
    }

    function _refinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature
    ) internal {
        if (lien.collection != offer.collection) {
            revert CollectionsDoNotMatch();
        }

        if (lien.currency != offer.currency) {
            revert CurrenciesDoNotMatch();
        }

        if (lien.amount != offer.collateralAmount) {
            revert InvalidCollateralAmount();
        }

        if (lien.collateralType != CollateralVerifier.mapCollateralType(offer.collateralType)) {
            revert InvalidCollateralType();
        }

        /* Update lien with new loan details. */
        Lien memory newLien = Lien({
            lender: offer.lender,
            borrower: lien.borrower,
            collateralType: lien.collateralType,
            collection: lien.collection,
            amount: lien.amount,
            tokenId: lien.tokenId,
            currency: lien.currency,
            borrowAmount: loanAmount,
            startTime: block.timestamp,
            duration: offer.duration,
            rate: offer.rate
        });

        unchecked {
            liens[lienId] = keccak256(abi.encode(newLien));
        }

        /* Take the loan offer. */
        _takeLoanOffer(offer, auth, offerSignature, authSignature, newLien, lienId);

        emit Refinance(
            lienId,
            offer.collection,
            offer.currency,
            lien.amount,
            lien.lender,
            newLien.lender,
            lien.borrowAmount,
            newLien.borrowAmount,
            lien.rate,
            newLien.rate
        );
    }

    /*//////////////////////////////////////////////////
                    DEFAULT FLOWS
    //////////////////////////////////////////////////*/

    /**
     * @notice Seizes collateral from defaulted lien, skipping liens that are not defaulted
     * @param lienPointers List of lien, lienId pairs
     */
    function seize(LienPointer[] calldata lienPointers) external {
        uint256 length = lienPointers.length;

        for (uint256 i; i < length; ) {
            Lien calldata lien = lienPointers[i].lien;
            uint256 lienId = lienPointers[i].lienId;

            if (msg.sender != lien.lender) {
                revert Unauthorized();
            }

            if (!_validateLien(lien, lienId)) {
                revert InvalidLien();
            }

            if (!_lienIsDefaulted(lien)) {
                revert LienNotDefaulted();
            }

            /* Check that the auction has ended and lien is defaulted. */
            delete liens[lienId];

            /* Seize collateral to lender. */
            SafeTransfer.transfer(
                lien.collateralType, 
                lien.collection, 
                getEscrow(lien.collection), 
                lien.lender, 
                lien.tokenId, 
                lien.amount
            );

            emit Seize(lienId, lien.collection);

            unchecked {
                ++i;
            }
        }
    }

    /*/////////////////////////////////////////////////////////////
                        VALIDATION MODIFIERS
    /////////////////////////////////////////////////////////////*/

    modifier validateLien(Lien calldata lien, uint256 lienId) {
        if (!_validateLien(lien, lienId)) {
            revert InvalidLien();
        }

        _;
    }

    modifier validateLiens(RepayFullfillment[] calldata repayments) {
        uint256 length = repayments.length;
        for (uint256 i; i < length; ) {
            Lien calldata lien = repayments[i].lien;
            uint256 lienId = repayments[i].lienId;

            if (!_validateLien(lien, lienId)) {
                revert InvalidLien();
            }

            unchecked {
                ++i;
            }
        }

        _;
    }

    modifier lienIsActive(Lien calldata lien) {
        if (_lienIsDefaulted(lien)) {
            revert LienIsDefaulted();
        }

        _;
    }

    modifier liensAreActive(RepayFullfillment[] calldata repayments) {
        uint256 length = repayments.length;
        for (uint256 i; i < length; ) {
            Lien calldata lien = repayments[i].lien;

            if (_lienIsDefaulted(lien)) {
                revert LienIsDefaulted();
            }

            unchecked {
                ++i;
            }
        }

        _;
    }

    function _validateLien(
        Lien calldata lien,
        uint256 lienId
    ) internal view returns (bool) {
        return liens[lienId] == keccak256(abi.encode(lien));
    }

    function _lienIsDefaulted(Lien calldata lien) internal view returns (bool) {
        return lien.startTime + lien.duration < block.timestamp;
    }
}