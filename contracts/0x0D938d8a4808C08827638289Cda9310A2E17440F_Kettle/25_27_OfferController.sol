// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Helpers } from "./Helpers.sol";

import { IOfferController } from "./interfaces/IOfferController.sol";
import { Lien, LoanOffer, BorrowOffer, OfferAuth, Collateral } from "./lib/Structs.sol";
import { Signatures } from "./lib/Signatures.sol";

import { InvalidLoanAmount, InsufficientOffer, RateTooHigh, OfferExpired, OfferUnavailable, UnauthorizedOffer, UnauthorizedCollateral, UnauthorizedTaker, AuthorizationExpired } from "./lib/Errors.sol";

contract OfferController is IOfferController, Ownable, Signatures {
    uint256 private constant _LIQUIDATION_THRESHOLD = 100_000;

    mapping(address => mapping(uint256 => uint256)) public cancelledOrFulfilled;
    mapping(bytes32 => uint256) private _amountTaken;
    address public _AUTH_SIGNER;
    uint256[50] private _gap;

    constructor (address authSigner) {
        setAuthSigner(authSigner);
    }

    function setAuthSigner(address authSigner) public onlyOwner {
        _AUTH_SIGNER = authSigner;
    }

    function amountTaken(bytes32 offerHash) external view returns (uint256) {
        return _amountTaken[offerHash];
    }

    /**
     * @notice Verifies and takes loan offer
     * @dev Does not transfer loan and collateral assets; does not update lien hash
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Lender offer signature
     * @param authSignature Auth Signer signature
     * @param lien Lien preimage
     * @param lienId Lien id
     */
    function _takeLoanOffer(
        LoanOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        Lien memory lien,
        uint256 lienId
    ) internal {
        bytes32 hash = _hashLoanOffer(offer);

        _validateOffer(
            hash,
            offer.lender,
            offerSignature,
            offer.expiration,
            offer.salt
        );

        _validateAuth(
            hash, 
            msg.sender, 
            auth, 
            lien, 
            authSignature
        );

        if (offer.rate > _LIQUIDATION_THRESHOLD) {
            revert RateTooHigh();
        }
        if (
            lien.borrowAmount > offer.maxAmount ||
            lien.borrowAmount < offer.minAmount
        ) {
            revert InvalidLoanAmount();
        }
        uint256 __amountTaken = _amountTaken[hash];
        if (offer.totalAmount - __amountTaken < lien.borrowAmount) {
            revert InsufficientOffer();
        }

        unchecked {
            _amountTaken[hash] = __amountTaken + lien.borrowAmount;
        }

        uint256 netBorrowAmount = Helpers.computeAmountAfterFees(
            lien.borrowAmount,
            offer.fees
        );

        emit LoanOfferTaken(
            hash,
            lienId,
            lien.lender,
            lien.borrower,
            lien.currency,
            lien.collateralType,
            lien.collection,
            lien.tokenId,
            lien.amount,
            lien.borrowAmount,
            netBorrowAmount,
            lien.rate,
            lien.duration,
            block.timestamp
        );
    }

    /**
     * @notice Verifies and takes loan offer
     * @dev Does not transfer loan and collateral assets; does not update lien hash
     * @param offer Loan offer
     * @param auth Offer auth
     * @param offerSignature Lender offer signature
     * @param authSignature Auth signer signature
     * @param lien Lien preimage
     * @param lienId Lien id
     */
    function _takeBorrowOffer(
        BorrowOffer calldata offer,
        OfferAuth calldata auth,
        bytes calldata offerSignature,
        bytes calldata authSignature,
        Lien memory lien,
        uint256 lienId
    ) internal {
        bytes32 hash = _hashBorrowOffer(offer);

        _validateOffer(
            hash,
            offer.borrower,
            offerSignature,
            offer.expiration,
            offer.salt
        );

        _validateAuth(
            hash, 
            msg.sender, 
            auth,
            lien, 
            authSignature
        );

        if (offer.rate > _LIQUIDATION_THRESHOLD) {
            revert RateTooHigh();
        }

        cancelledOrFulfilled[offer.borrower][offer.salt] = 1;

        uint256 netBorrowAmount = Helpers.computeAmountAfterFees(
            lien.borrowAmount,
            offer.fees
        );

        emit LoanOfferTaken(
            hash,
            lienId,
            lien.lender,
            lien.borrower,
            lien.currency,
            lien.collateralType,
            lien.collection,
            lien.tokenId,
            lien.amount,
            lien.borrowAmount,
            netBorrowAmount,
            lien.rate,
            lien.duration,
            block.timestamp
        );
    }

    function _validateAuth(
        bytes32 offerHash,
        address taker,
        OfferAuth calldata auth,
        Lien memory lien,
        bytes calldata signature
    ) internal view {

        bytes32 collateralHash = _hashCollateral(
            lien.collateralType,
            lien.collection,
            lien.tokenId,
            lien.amount
        );

        bytes32 authHash = _hashOfferAuth(auth);
        _verifyOfferAuthorization(authHash, _AUTH_SIGNER, signature);

        if (auth.expiration < block.timestamp) {
            revert AuthorizationExpired();
        }

        if (auth.taker != taker) {
            revert UnauthorizedTaker();
        }

        if (auth.offerHash != offerHash) {
            revert UnauthorizedOffer();
        }

        if (auth.collateralHash != collateralHash) {
            revert UnauthorizedCollateral();
        }
    }

    /**
     * @notice Assert offer validity
     * @param offerHash Offer hash
     * @param signer Address of offer signer
     * @param signature Packed signature array
     * @param expiration Offer expiration time
     * @param salt Offer salt
     */
    function _validateOffer(
        bytes32 offerHash,
        address signer,
        bytes calldata signature,
        uint256 expiration,
        uint256 salt
    ) internal view {
        _verifyOfferAuthorization(offerHash, signer, signature);

        if (expiration < block.timestamp) {
            revert OfferExpired();
        }
        if (cancelledOrFulfilled[signer][salt] == 1) {
            revert OfferUnavailable();
        }
    }

    /*/////////////////////////////////////////
                  CANCEL FUNCTIONS
    /////////////////////////////////////////*/
    /**
     * @notice Cancels offer salt for caller
     * @param salt Unique offer salt
     */
    function cancelOffer(uint256 salt) external {
        _cancelOffer(msg.sender, salt);
    }

    /**
     * @notice Cancels offers in bulk for caller
     * @param salts List of offer salts
     */
    function cancelOffers(uint256[] calldata salts) external {
        uint256 saltsLength = salts.length;
        for (uint256 i; i < saltsLength; ) {
            _cancelOffer(msg.sender, salts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancels all offers by incrementing caller nonce
     */
    function incrementNonce() external {
        _incrementNonce(msg.sender);
    }

    /**
     * @notice Cancel offer by user and salt
     * @param user Address of user
     * @param salt Unique offer salt
     */
    function _cancelOffer(address user, uint256 salt) private {
        cancelledOrFulfilled[user][salt] = 1;
        emit OfferCancelled(user, salt);
    }

    /**
     * @notice Cancel all orders by incrementing the user nonce
     * @param user Address of user
     */
    function _incrementNonce(address user) internal {
        emit NonceIncremented(user, ++nonces[user]);
    }
}