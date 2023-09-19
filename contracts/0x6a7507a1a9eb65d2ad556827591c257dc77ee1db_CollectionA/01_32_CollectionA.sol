// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./modules/AffiliableA.sol";
import "../interface/ICollectionStruct.sol";
import "./ContractMetadata.sol";

/// @title CollectionA
/// @author Chain Labs
/// @notice Main contract that is made up of building blocks and is ready to be used that extends the affiliate functionality.
/// @dev Inherits all the modules and base collection
contract CollectionA is ICollectionStruct, AffiliableA, ContractMetadata {
    /// @notice setup collection
    /// @dev setup all the modules and base collection
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens
    ) external {
        _setup(
            _baseCollection,
            _presaleable,
            _paymentSplitter,
            _projectURIProvenance,
            _royalties,
            _reserveTokens
        );
    }

    /// @notice setup collection with affiliate module
    /// @dev setup all the modules and base collection including affiliate module
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    /// @param _registry address of Simplr Affiliate registry
    /// @param _projectId project ID of Simplr Collection
    function setupWithAffiliate(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens,
        IAffiliateRegistry _registry,
        bytes32 _projectId
    ) external {
        _setup(
            _baseCollection,
            _presaleable,
            _paymentSplitter,
            _projectURIProvenance,
            _royalties,
            _reserveTokens
        );
        _setAffiliateModule(_registry, _projectId);
    }

    /// @notice internal method to setup collection
    /// @dev internal method to setup all the modules and base collection
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    function _setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens
    ) private initializer {
        setupBaseCollection(
            _baseCollection.name,
            _baseCollection.symbol,
            _baseCollection.admin,
            _baseCollection.maximumTokens,
            _baseCollection.maxPurchase,
            _baseCollection.maxHolding,
            _baseCollection.price,
            _baseCollection.publicSaleStartTime,
            _baseCollection.projectURI
        );
        setupPresale(
            _presaleable.presaleReservedTokens,
            _presaleable.presalePrice,
            _presaleable.presaleStartTime,
            _presaleable.presaleMaxHolding,
            _presaleable.presaleWhitelist
        );
        setupPaymentSplitter(
            _paymentSplitter.simplr,
            _paymentSplitter.simplrShares,
            _paymentSplitter.payees,
            _paymentSplitter.shares
        );
        setProvenance(_projectURIProvenance);
        _setReserveTokens(_reserveTokens);
        _setRoyalties(_royalties);
    }
}