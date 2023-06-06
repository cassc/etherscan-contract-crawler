// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../../utils/DataTypes.sol";
import "../../utils/LoanDataTypes.sol";
import "../Interfaces/lib/ISigningUtils.sol";

/// @title NF3 Signing Utils
/// @author NF3 Exchange
/// @dev  Helper contract for Protocol. This contract manages verifying signatures
///       from off-chain Protocol orders.

contract SigningUtil is EIP712, ISigningUtils {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------
    using ECDSA for bytes32;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    bytes32 private immutable ASSETS_TYPE_HASH;
    bytes32 private immutable SWAP_ASSETS_TYPE_HASH;
    bytes32 private immutable RESERVE_INFO_TYPE_HASH;
    bytes32 private immutable ROYALTY_TYPE_HASH;
    bytes32 private immutable LISTING_TYPE_HASH;
    bytes32 private immutable SWAP_OFFER_TYPE_HASH;
    bytes32 private immutable RESERVE_OFFER_TYPE_HASH;
    bytes32 private immutable COLLECTION_SWAP_OFFER_TYPE_HASH;
    bytes32 private immutable COLLECTION_RESERVE_OFFER_TYPE_HASH;
    bytes32 private immutable LOAN_OFFER_TYPE_HASH;
    bytes32 private immutable COLLECTION_LOAN_OFFER_TYPE_HASH;
    bytes32 private immutable LOAN_UPDATE_OFFER_TYPE_HASH;

    /* ===== INIT ===== */

    /// @dev Constructor
    /// @param _name Name of the protcol
    /// @param _version Version of the protocol
    /// @dev Calculate and set type hashes for all the structs and nested structs types
    constructor(string memory _name, string memory _version)
        EIP712(_name, _version)
    {
        // build individual type strings
        bytes memory assetsTypeString = abi.encodePacked(
            "Assets(",
            "address[] tokens,",
            "uint256[] tokenIds,",
            "address[] paymentTokens,",
            "uint256[] amounts",
            ")"
        );

        bytes memory swapAssetsTypeString = abi.encodePacked(
            "SwapAssets(",
            "address[] tokens,",
            "bytes32[] roots,",
            "address[] paymentTokens,",
            "uint256[] amounts",
            ")"
        );

        bytes memory reserveInfoTypeString = abi.encodePacked(
            "ReserveInfo(",
            "Assets deposit,",
            "Assets remaining,",
            "uint256 duration",
            ")"
        );

        bytes memory royaltyTypeString = abi.encodePacked(
            "Royalty(",
            "address[] to,",
            "uint256[] percentage",
            ")"
        );

        bytes memory listingTypeString = abi.encodePacked(
            "Listing(",
            "Assets listingAssets,"
            "SwapAssets[] directSwaps,"
            "ReserveInfo[] reserves,"
            "Royalty royalty,"
            "address tradeIntendedFor,"
            "uint256 timePeriod,"
            "address owner,"
            "uint256 nonce"
            ")"
        );

        bytes memory swapOfferTypeString = abi.encodePacked(
            "SwapOffer(",
            "Assets offeringItems,",
            "Royalty royalty,",
            "bytes32 considerationRoot,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory reserveOfferTypeString = abi.encodePacked(
            "ReserveOffer(",
            "ReserveInfo reserveDetails,",
            "bytes32 considerationRoot,",
            "Royalty royalty,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory collectionSwapOfferTypeString = abi.encodePacked(
            "CollectionSwapOffer(",
            "Assets offeringItems,",
            "SwapAssets considerationItems,",
            "Royalty royalty,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory collectionReserveOfferTypeString = abi.encodePacked(
            "CollectionReserveOffer(",
            "ReserveInfo reserveDetails,",
            "SwapAssets considerationItems,",
            "Royalty royalty,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory loanOfferTypeString = abi.encodePacked(
            "LoanOffer(",
            "address nftCollateralContract,",
            "uint256 nftCollateralId,",
            "address owner,",
            "uint256 nonce,",
            "address loanPaymentToken,",
            "uint256 loanPrincipalAmount,",
            "uint256 maximumRepaymentAmount,",
            "uint256 loanDuration,",
            "uint256 loanInterestRate,",
            "uint256 adminFees,",
            "bool isLoanProrated,",
            "bool isBorrowerTerms",
            ")"
        );

        bytes memory collectionLoanOfferTypeString = abi.encodePacked(
            "CollectionLoanOffer(",
            "address nftCollateralContract,",
            "bytes32 nftCollateralIdRoot,",
            "address owner,",
            "uint256 nonce,",
            "address loanPaymentToken,",
            "uint256 loanPrincipalAmount,",
            "uint256 maximumRepaymentAmount,",
            "uint256 loanDuration,",
            "uint256 loanInterestRate,",
            "uint256 adminFees,",
            "bool isLoanProrated",
            ")"
        );

        bytes memory loanUpdateOfferTypeString = abi.encodePacked(
            "LoanUpdateOffer(",
            "uint256 loanId,",
            "uint256 maximumRepaymentAmount,",
            "uint256 loanDuration,",
            "uint256 loanInterestRate,",
            "address owner,",
            "uint256 nonce,",
            "bool isLoanProrated,",
            "bool isBorrowerTerms",
            ")"
        );

        // build collective type strings and type hashes
        SWAP_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                swapOfferTypeString,
                assetsTypeString,
                royaltyTypeString
            )
        );
        RESERVE_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                reserveOfferTypeString,
                assetsTypeString,
                reserveInfoTypeString,
                royaltyTypeString
            )
        );
        COLLECTION_SWAP_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                collectionSwapOfferTypeString,
                assetsTypeString,
                royaltyTypeString,
                swapAssetsTypeString
            )
        );
        COLLECTION_RESERVE_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                collectionReserveOfferTypeString,
                assetsTypeString,
                reserveInfoTypeString,
                royaltyTypeString,
                swapAssetsTypeString
            )
        );
        ASSETS_TYPE_HASH = keccak256(assetsTypeString);
        SWAP_ASSETS_TYPE_HASH = keccak256(swapAssetsTypeString);
        RESERVE_INFO_TYPE_HASH = keccak256(
            abi.encodePacked(reserveInfoTypeString, assetsTypeString)
        );
        ROYALTY_TYPE_HASH = keccak256(royaltyTypeString);
        LISTING_TYPE_HASH = keccak256(
            abi.encodePacked(
                listingTypeString,
                assetsTypeString,
                reserveInfoTypeString,
                royaltyTypeString,
                swapAssetsTypeString
            )
        );
        LOAN_OFFER_TYPE_HASH = keccak256(loanOfferTypeString);
        COLLECTION_LOAN_OFFER_TYPE_HASH = keccak256(
            collectionLoanOfferTypeString
        );
        LOAN_UPDATE_OFFER_TYPE_HASH = keccak256(loanUpdateOfferTypeString);
    }

    /// -----------------------------------------------------------------------
    /// Signature Verification Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISigningUtils
    function verifyListingSignature(
        Listing calldata listing,
        bytes memory signature
    ) external view override {
        uint256 swapCount = listing.directSwaps.length;
        uint256 reserveCount = listing.reserves.length;
        bytes32[] memory directSwapHashes = new bytes32[](swapCount);
        bytes32[] memory reserveHashes = new bytes32[](reserveCount);
        for (uint256 i = 0; i < swapCount; ++i) {
            directSwapHashes[i] = _hashSwapAssets(listing.directSwaps[i]);
        }
        for (uint256 i = 0; i < reserveCount; ++i) {
            reserveHashes[i] = _hashReserve(listing.reserves[i]);
        }

        bytes32 listingHash = keccak256(
            abi.encode(
                LISTING_TYPE_HASH,
                _hashAssets(listing.listingAssets),
                keccak256(abi.encodePacked(directSwapHashes)),
                keccak256(abi.encodePacked(reserveHashes)),
                _hashRoyalty(listing.royalty),
                listing.tradeIntendedFor,
                listing.timePeriod,
                listing.owner,
                listing.nonce
            )
        );

        address signer = _hashTypedDataV4(listingHash).recover(signature);

        if (listing.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_LISTING_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifySwapOfferSignature(
        SwapOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 swapOfferHash = keccak256(
            abi.encode(
                SWAP_OFFER_TYPE_HASH,
                _hashAssets(offer.offeringItems),
                _hashRoyalty(offer.royalty),
                offer.considerationRoot,
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(swapOfferHash).recover(signature);
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_SWAP_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 collectionSwapOfferHash = keccak256(
            abi.encode(
                COLLECTION_SWAP_OFFER_TYPE_HASH,
                _hashAssets(offer.offeringItems),
                _hashSwapAssets(offer.considerationItems),
                _hashRoyalty(offer.royalty),
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(collectionSwapOfferHash).recover(
            signature
        );
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_COLLECTION_SWAP_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyReserveOfferSignature(
        ReserveOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 reserveOfferHash = keccak256(
            abi.encode(
                RESERVE_OFFER_TYPE_HASH,
                _hashReserve(offer.reserveDetails),
                offer.considerationRoot,
                _hashRoyalty(offer.royalty),
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(reserveOfferHash).recover(signature);
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_RESERVE_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 collectionReserveOffer = keccak256(
            abi.encode(
                COLLECTION_RESERVE_OFFER_TYPE_HASH,
                _hashReserve(offer.reserveDetails),
                _hashSwapAssets(offer.considerationItems),
                _hashRoyalty(offer.royalty),
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(collectionReserveOffer).recover(
            signature
        );
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes
                    .INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyLoanOfferSignature(
        LoanOffer calldata offer,
        bytes memory signature
    ) external view override {
        // splitting the acutal string to be hashed in two parts
        // workaround to prevent stack too deep error -_-
        bytes memory secondHalf = abi.encode(
            offer.loanDuration,
            offer.loanInterestRate,
            offer.adminFees,
            offer.isLoanProrated,
            offer.isBorrowerTerms
        );
        bytes memory firstHalf = abi.encode(
            LOAN_OFFER_TYPE_HASH,
            offer.nftCollateralContract,
            offer.nftCollateralId,
            offer.owner,
            offer.nonce,
            offer.loanPaymentToken,
            offer.loanPrincipalAmount,
            offer.maximumRepaymentAmount
        );
        bytes32 loanOffer = keccak256(abi.encodePacked(firstHalf, secondHalf));
        address signer = _hashTypedDataV4(loanOffer).recover(signature);

        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 collectionLoanOffer = keccak256(
            abi.encode(
                COLLECTION_LOAN_OFFER_TYPE_HASH,
                offer.nftCollateralContract,
                offer.nftCollateralIdRoot,
                offer.owner,
                offer.nonce,
                offer.loanPaymentToken,
                offer.loanPrincipalAmount,
                offer.maximumRepaymentAmount,
                offer.loanDuration,
                offer.loanInterestRate,
                offer.adminFees,
                offer.isLoanProrated
            )
        );
        address signer = _hashTypedDataV4(collectionLoanOffer).recover(
            signature
        );
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_COLLECTION_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 loanUpdateOffer = keccak256(
            abi.encode(
                LOAN_UPDATE_OFFER_TYPE_HASH,
                offer.loanId,
                offer.maximumRepaymentAmount,
                offer.loanDuration,
                offer.loanInterestRate,
                offer.owner,
                offer.nonce,
                offer.isLoanProrated,
                offer.isBorrowerTerms
            )
        );
        address signer = _hashTypedDataV4(loanUpdateOffer).recover(signature);
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_UPDATE_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Get eip 712 compliant hash for Royalty struct type
    /// @param royalty Royalty struct to be hashed
    function _hashRoyalty(Royalty calldata royalty)
        internal
        view
        returns (bytes32)
    {
        bytes32 royaltyHash = keccak256(
            abi.encode(
                ROYALTY_TYPE_HASH,
                keccak256(abi.encodePacked(royalty.to)),
                keccak256(abi.encodePacked(royalty.percentage))
            )
        );
        return royaltyHash;
    }

    /// @dev Get eip 712 compliant hash for ReserveInfo struct type
    /// @param reserve ReserveInfo struct to be hashed
    function _hashReserve(ReserveInfo calldata reserve)
        internal
        view
        returns (bytes32)
    {
        bytes32 reserveHash = keccak256(
            abi.encode(
                RESERVE_INFO_TYPE_HASH,
                _hashAssets(reserve.deposit),
                _hashAssets(reserve.remaining),
                reserve.duration
            )
        );
        return reserveHash;
    }

    /// @dev Get eip 712 compliant hash for SwapAssets struct type
    /// @param directSwap SwapAssets struct to be hashed
    function _hashSwapAssets(SwapAssets calldata directSwap)
        internal
        view
        returns (bytes32)
    {
        bytes32 assetsTypeHash = keccak256(
            abi.encode(
                SWAP_ASSETS_TYPE_HASH,
                keccak256(abi.encodePacked(directSwap.tokens)),
                keccak256(abi.encodePacked(directSwap.roots)),
                keccak256(abi.encodePacked(directSwap.paymentTokens)),
                keccak256(abi.encodePacked(directSwap.amounts))
            )
        );
        return assetsTypeHash;
    }

    /// @dev Get eip 712 compliant hash for Assets struct type
    /// @param _assets Assets struct to be hashed
    function _hashAssets(Assets calldata _assets)
        internal
        view
        returns (bytes32)
    {
        bytes32 assetsTypeHash = keccak256(
            abi.encode(
                ASSETS_TYPE_HASH,
                keccak256(abi.encodePacked(_assets.tokens)),
                keccak256(abi.encodePacked(_assets.tokenIds)),
                keccak256(abi.encodePacked(_assets.paymentTokens)),
                keccak256(abi.encodePacked(_assets.amounts))
            )
        );
        return assetsTypeHash;
    }
}