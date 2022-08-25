// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../../libraries/math/MathUtils.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../interfaces/IOpenSkyPool.sol';
import '../../interfaces/IOpenSkySettings.sol';

import './BespokeTypes.sol';
import './SignatureChecker.sol';
import '../interfaces/IOpenSkyBespokeSettings.sol';

library BespokeLogic {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    // keccak256("BorrowOffer(uint256 reserveId,address nftAddress,uint256 tokenId,uint256 tokenAmount,address borrower,uint256 borrowAmountMin,uint256 borrowAmountMax,uint40 borrowDurationMin,uint40 borrowDurationMax,uint128 borrowRate,address currency,uint256 nonce,uint256 deadline)")
    bytes32 internal constant BORROW_OFFER_HASH = 0xacdf87371514724eb8e74db090d21dbc2361a02a72e2facac480fe7964ae4feb;

    function hashBorrowOffer(BespokeTypes.BorrowOffer memory offerData) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BORROW_OFFER_HASH,
                    offerData.reserveId,
                    offerData.nftAddress,
                    offerData.tokenId,
                    offerData.tokenAmount,
                    offerData.borrower,
                    offerData.borrowAmountMin,
                    offerData.borrowAmountMax,
                    offerData.borrowDurationMin,
                    offerData.borrowDurationMax,
                    offerData.borrowRate,
                    offerData.currency,
                    offerData.nonce,
                    offerData.deadline
                )
            );
    }

    function validateTakeBorrowOffer(
        mapping(address => mapping(uint256 => bool)) storage _nonce,
        mapping(address => uint256) storage minNonce,
        BespokeTypes.BorrowOffer memory offerData,
        bytes32 offerHash,
        address underlyingSpecified,
        uint256 supplyAmount,
        uint256 supplyDuration,
        bytes32 DOMAIN_SEPARATOR,
        IOpenSkyBespokeSettings BESPOKE_SETTINGS,
        IOpenSkySettings SETTINGS
    ) public {
        // check nonce
        require(
            !_nonce[offerData.borrower][offerData.nonce] && offerData.nonce >= minNonce[offerData.borrower],
            'BM_TAKE_BORROW_NONCE_INVALID'
        );

        address underlyingAsset = IOpenSkyPool(SETTINGS.poolAddress())
            .getReserveData(offerData.reserveId)
            .underlyingAsset;

        require(underlyingAsset == offerData.currency, 'BM_TAKE_BORROW_OFFER_ASSET_NOT_MATCH');

        if (underlyingSpecified != address(0))
            require(underlyingAsset == underlyingSpecified, 'BM_TAKE_BORROW_OFFER_ASSET_SPECIFIED_NOT_MATCH');

        require(BESPOKE_SETTINGS.isCurrencyWhitelisted(offerData.currency), 'BM_TAKE_BORROW_CURRENCY_NOT_IN_WHITELIST');

        require(
            !BESPOKE_SETTINGS.isWhitelistOn() || BESPOKE_SETTINGS.inWhitelist(offerData.nftAddress),
            'BM_TAKE_BORROW_NFT_NOT_IN_WHITELIST'
        );

        require(block.timestamp <= offerData.deadline, 'BM_TAKE_BORROW_SIGNING_EXPIRATION');

        (uint256 minBorrowDuration, uint256 maxBorrowDuration, ) = BESPOKE_SETTINGS.getBorrowDurationConfig(
            offerData.nftAddress
        );

        // check borrow duration
        require(
            offerData.borrowDurationMin <= offerData.borrowDurationMax &&
                offerData.borrowDurationMin >= minBorrowDuration &&
                offerData.borrowDurationMax <= maxBorrowDuration,
            'BM_TAKE_BORROW_OFFER_DURATION_NOT_ALLOWED'
        );

        require(
            supplyDuration > 0 &&
                supplyDuration >= offerData.borrowDurationMin &&
                supplyDuration <= offerData.borrowDurationMax,
            'BM_TAKE_BORROW_TAKER_DURATION_NOT_ALLOWED'
        );

        // check borrow amount
        require(
            offerData.borrowAmountMin > 0 && offerData.borrowAmountMin <= offerData.borrowAmountMax,
            'BM_TAKE_BORROW_OFFER_AMOUNT_NOT_ALLOWED'
        );

        require(
            supplyAmount >= offerData.borrowAmountMin && supplyAmount <= offerData.borrowAmountMax,
            'BM_TAKE_BORROW_SUPPLY_AMOUNT_NOT_ALLOWED'
        );
        require(
            SignatureChecker.verify(
                offerHash,
                offerData.borrower,
                offerData.v,
                offerData.r,
                offerData.s,
                DOMAIN_SEPARATOR
            ),
            'BM_TAKE_BORROW_SIGNATURE_INVALID'
        );
    }

    function createLoan(
        mapping(uint256 => BespokeTypes.LoanData) storage _loans,
        BespokeTypes.BorrowOffer memory offerData,
        uint256 loanId,
        uint256 supplyAmount,
        uint256 supplyDuration,
        IOpenSkyBespokeSettings BESPOKE_SETTINGS
    ) public {
        uint256 borrowRateRay = uint256(offerData.borrowRate).rayDiv(10000);
        (, , uint256 overdueDuration) = BESPOKE_SETTINGS.getBorrowDurationConfig(offerData.nftAddress);

        BespokeTypes.LoanData memory loan = BespokeTypes.LoanData({
            reserveId: offerData.reserveId,
            nftAddress: offerData.nftAddress,
            tokenId: offerData.tokenId,
            tokenAmount: offerData.tokenAmount,
            borrower: offerData.borrower,
            amount: supplyAmount,
            borrowRate: uint128(borrowRateRay),
            interestPerSecond: uint128(MathUtils.calculateBorrowInterestPerSecond(borrowRateRay, supplyAmount)),
            currency: offerData.currency,
            borrowDuration: uint40(supplyDuration),
            borrowBegin: uint40(block.timestamp),
            borrowOverdueTime: uint40(block.timestamp.add(supplyDuration)),
            liquidatableTime: uint40(block.timestamp.add(supplyDuration).add(overdueDuration)),
            lender: msg.sender,
            status: BespokeTypes.LoanStatus.BORROWING
        });

        _loans[loanId] = loan;
    }
}