// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISwap } from "./Interfaces/ISwap.sol";
import { IVault } from "./Interfaces/IVault.sol";
import { IStorageRegistry } from "./Interfaces/IStorageRegistry.sol";
import { ISigningUtils } from "./Interfaces/lib/ISigningUtils.sol";
import { ValidationUtils } from "./lib/ValidationUtils.sol";
import "../utils/DataTypes.sol";

/// @title NF3 Swap
/// @author NF3 Exchange
/// @notice This contract inherits from ISwap interface.
/// @dev Functions in this contract are not public callable. They can only be called through the public facing contract(NF3Proxy).
/// @dev This contract has the functions related to all types of swaps.

contract Swap is ISwap, Ownable {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using ValidationUtils for *;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Storage registry contract address
    address public storageRegistryAddress;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyMarket() {
        _onlyMarket();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function cancelListing(
        Listing calldata _listing,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        // Verify signature.
        ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
            .verifyListingSignature(_listing, _signature);

        // Should be called by the listing owner.
        _listing.owner.itemOwnerOnly(_user);

        _checkNonce(_listing.owner, _listing.nonce, _storageRegistryAddress);

        _setNonce(_listing.owner, _listing.nonce, _storageRegistryAddress);

        emit ListingCancelled(_listing);
    }

    /// @notice Inherit from ISwap
    function cancelSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        // Verify signature.
        ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
            .verifySwapOfferSignature(_offer, _signature);

        // Should be called by the offer owner.
        _offer.owner.itemOwnerOnly(_user);

        _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        emit SwapOfferCancelled(_offer);
    }

    /// @notice Inherit from ISwap
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        // Verify signature.
        ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
            .verifyCollectionSwapOfferSignature(_offer, _signature);

        // Should be called by the offer owner.
        _offer.owner.itemOwnerOnly(_user);

        _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        emit CollectionSwapOfferCancelled(_offer);
    }

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function directSwap(
        Listing calldata _listing,
        bytes memory _signature,
        uint256 _swapId,
        address _user,
        SwapParams memory swapParams,
        uint256 _value,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        {
            // Verify signature, nonce and expiration.
            ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
                .verifyListingSignature(_listing, _signature);

            _checkNonce(
                _listing.owner,
                _listing.nonce,
                _storageRegistryAddress
            );

            checkExpiration(_listing.timePeriod);

            // check if called by eligible contract
            address intendedFor = _listing.tradeIntendedFor;
            if (!(intendedFor == address(0) || intendedFor == _user)) {
                revert SwapError(
                    SwapErrorCodes.INTENDED_FOR_PEER_TO_PEER_TRADE
                );
            }

            // Seller should not buy his own listing.
            _listing.owner.notItemOwner(_user);
        }

        // Verify swap option with swapId exist.
        SwapAssets memory swapAssets = swapExists(
            _listing.directSwaps,
            _swapId
        );

        // Verfy incoming assets to be the same.
        Assets memory offeredAssets = swapAssets.verifySwapAssets(
            swapParams.tokens,
            swapParams.tokenIds,
            swapParams.proofs,
            _value
        );
        // to prevent stack too deep
        Listing calldata listing = _listing;

        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);

            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                listing.listingAssets,
                listing.owner,
                _user,
                _royalty,
                false
            );

            IVault(vaultAddress).transferAssets(
                offeredAssets,
                _user,
                listing.owner,
                listing.royalty,
                true
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                listing.owner,
                buyerFees,
                _user
            );
        }

        // Update the nonce.
        _setNonce(listing.owner, listing.nonce, _storageRegistryAddress);

        emit DirectSwapped(listing, offeredAssets, _swapId, _user);
    }

    /// @notice Inherit from ISwap
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        address _user,
        uint256 _value,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        {
            // Verify signature, nonce and expiration.
            ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
                .verifySwapOfferSignature(_offer, _signature);

            _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

            checkExpiration(_offer.timePeriod);

            // Seller should not accept his own offer.
            _offer.owner.notItemOwner(_user);

            // Verify incomming assets to be present in the merkle root.
            _offer.considerationRoot.verifyAssetProof(_consideration, _proof);

            // Check if enough eth amount is sent.
            _consideration.checkEthAmount(_value);
        }

        // to prevent stack too deep
        SwapOffer calldata offer = _offer;

        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);

            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                offer.offeringItems,
                offer.owner,
                _user,
                _royalty,
                false
            );

            IVault(vaultAddress).transferAssets(
                _consideration,
                _user,
                offer.owner,
                offer.royalty,
                true
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                _user,
                buyerFees,
                offer.owner
            );
        }

        // Update the nonce.
        _setNonce(offer.owner, offer.nonce, _storageRegistryAddress);

        emit UnlistedSwapOfferAccepted(offer, _consideration, _user);
    }

    /// @notice Inherit from ISwap
    function acceptListedDirectSwapOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        SwapOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] calldata _proof,
        address _user,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;

        {
            address __signingUtilsAddress = _signingUtilsAddress(
                _storageRegistryAddress
            );

            // Verify listing signature, nonce and expiration.
            ISigningUtils(__signingUtilsAddress).verifyListingSignature(
                _listing,
                _listingSignature
            );

            _checkNonce(
                _listing.owner,
                _listing.nonce,
                _storageRegistryAddress
            );

            checkExpiration(_listing.timePeriod);

            // Verify offer signature, nonce and expiration.
            ISigningUtils(__signingUtilsAddress).verifySwapOfferSignature(
                _offer,
                _offerSignature
            );

            _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

            checkExpiration(_offer.timePeriod);

            // Should be called by listing owner.
            _listing.owner.itemOwnerOnly(_user);

            // Should not be called by the offer owner.
            _offer.owner.notItemOwner(_user);

            // Verify lisitng assets to be present in the offer's merkle root.
            _offer.considerationRoot.verifyAssetProof(
                _listing.listingAssets,
                _proof
            );
        }
        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);
            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                _listing.listingAssets,
                _listing.owner,
                _offer.owner,
                _offer.royalty,
                false
            );
            IVault(vaultAddress).transferAssets(
                _offer.offeringItems,
                _offer.owner,
                _listing.owner,
                _listing.royalty,
                false
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                _listing.owner,
                buyerFees,
                _offer.owner
            );
        }

        // Update the nonce.
        _setNonce(_listing.owner, _listing.nonce, _storageRegistryAddress);
        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

        emit ListedSwapOfferAccepted(_listing, _offer, _user);
    }

    /// @notice Inherit from ISwap
    function acceptCollectionSwapOffer(
        CollectionSwapOffer calldata _offer,
        bytes memory _signature,
        SwapParams memory swapParams,
        address _user,
        uint256 _value,
        Royalty calldata _royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external override onlyMarket {
        address _storageRegistryAddress = storageRegistryAddress;
        {
            // Verify signature, nonce and expiration.
            ISigningUtils(_signingUtilsAddress(_storageRegistryAddress))
                .verifyCollectionSwapOfferSignature(_offer, _signature);

            _checkNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);

            checkExpiration(_offer.timePeriod);

            // Seller must not be offer owner.
            _offer.owner.notItemOwner(_user);
        }

        // Verify incomming assets to be the same as consideration items.
        Assets memory offeredAssets = _offer
            .considerationItems
            .verifySwapAssets(
                swapParams.tokens,
                swapParams.tokenIds,
                swapParams.proofs,
                _value
            );

        {
            address vaultAddress = _vaultAddress(_storageRegistryAddress);

            // Exchange the assets.
            IVault(vaultAddress).transferAssets(
                _offer.offeringItems,
                _offer.owner,
                _user,
                _royalty,
                false
            );
            IVault(vaultAddress).transferAssets(
                offeredAssets,
                _user,
                _offer.owner,
                _offer.royalty,
                true
            );

            // transfer fees
            IVault(vaultAddress).transferFees(
                sellerFees,
                _user,
                buyerFees,
                _offer.owner
            );
        }

        // Update the nonce.
        _setNonce(_offer.owner, _offer.nonce, _storageRegistryAddress);
        emit CollectionSwapOfferAccepted(_offer, offeredAssets, _user);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function setStorageRegistry(address _storageRegistryAddress)
        external
        override
        onlyOwner
    {
        if (_storageRegistryAddress == address(0)) {
            revert SwapError(SwapErrorCodes.INVALID_ADDRESS);
        }

        emit StorageRegistrySet(
            _storageRegistryAddress,
            storageRegistryAddress
        );

        storageRegistryAddress = _storageRegistryAddress;
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Check if the give nonce is valid or not
    /// @param _user address of the user
    /// @param _nonce actual nonce to check
    /// @param _storageRegistryAddress memoized storage registry address
    function _checkNonce(
        address _user,
        uint256 _nonce,
        address _storageRegistryAddress
    ) internal view {
        IStorageRegistry(_storageRegistryAddress).checkNonce(_user, _nonce);
    }

    /// @dev Set the given nonce as used
    /// @param _user address of the user
    /// @param _nonce actual nonce to set
    /// @param _storageRegistryAddress memoized storage registry address
    function _setNonce(
        address _user,
        uint256 _nonce,
        address _storageRegistryAddress
    ) internal {
        IStorageRegistry(_storageRegistryAddress).setNonce(_user, _nonce);
    }

    /// @dev Check if the swap option with given swap id exist or not.
    /// @param _swaps All the swap options
    /// @param _swapId Swap id to be checked
    /// @return swap Swap assets at given index
    function swapExists(SwapAssets[] calldata _swaps, uint256 _swapId)
        internal
        pure
        returns (SwapAssets calldata)
    {
        if (_swaps.length <= _swapId) {
            revert SwapError(SwapErrorCodes.OPTION_DOES_NOT_EXIST);
        }
        return _swaps[_swapId];
    }

    /// @dev Check if the item has expired.
    /// @param _timePeriod Expiration time
    function checkExpiration(uint256 _timePeriod) internal view {
        if (_timePeriod < block.timestamp) {
            revert SwapError(SwapErrorCodes.ITEM_EXPIRED);
        }
    }

    /// @dev internal function to check if the caller is market or not
    function _onlyMarket() internal view {
        address marketAddress = IStorageRegistry(storageRegistryAddress)
            .marketAddress();
        if (msg.sender != marketAddress) {
            revert SwapError(SwapErrorCodes.NOT_MARKET);
        }
    }

    /// @dev internal function to get vault address from storage registry contract
    /// @param _storageRegistryAddress  memoized storage registry address
    function _vaultAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).vaultAddress();
    }

    /// @dev internal function to get signing utils library address from storage registry
    /// @param _storageRegistryAddress memoized storage registry address
    function _signingUtilsAddress(address _storageRegistryAddress)
        internal
        view
        returns (address)
    {
        return IStorageRegistry(_storageRegistryAddress).signingUtilsAddress();
    }
}