// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IChainzokuItem.sol";
import "./libs/interfaces/IERC1155Proxy.sol";
import "./libs/Initialize.sol";
import "./libs/Pause.sol";
import "./libs/Signature.sol";

// @author: miinded.com

contract ChainZokuBurnItems is IChainzokuItem, Initialize, Signature, ReentrancyGuard, Pause {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private internalIdFlagged;

    function init(
        address _signAddress
    ) public onlyOwner isNotInitialized {
        Signature.setSignAddress(_signAddress);
        Signature.setHashSign(784875);
    }

    function BurnItems(
        CollectionItems[] memory _collectionItems,
        uint256 _internalId,
        bytes memory _signature
    ) public notPaused signedUnique(_burnCollectionItemsValid(_collectionItems, _internalId), _internalId, _signature) nonReentrant {

        for (uint256 i = 0; i < _collectionItems.length; i++) {
            _burnItems(_collectionItems[i]);
        }
    }

    function _burnItems(CollectionItems memory _collectionItem) private {
        require(_collectionItem.action == Action.Burn, "ChainZokuBurnItems: action is not Burn");

        uint256 totalCount = 0;
        for (uint256 i = 0; i < _collectionItem.counts.length; i++) {
            totalCount += _collectionItem.counts[i];
        }
        require(_collectionItem.internalIds.length == totalCount, "ChainZokuBurnItems: internalIds length mismatch");

        for (uint256 i = 0; i < _collectionItem.internalIds.length; i++) {
            _flagInternalId(_collectionItem.internalIds[i]);
        }

        IERC1155Proxy(_collectionItem.collection).burnBatch(_msgSender(), _collectionItem.ids, _collectionItem.counts);

        emit FlagItems(_collectionItem.internalIds, uint8(_collectionItem.action), 0);
    }

    function _flagInternalId(uint256 _internalId) internal {
        require(internalIdFlagged.get(_internalId) == false, "ChainZokuBurnItems: internalId already flag");
        internalIdFlagged.set(_internalId);
    }

    function _burnCollectionItemsValid(CollectionItems[] memory _items, uint256 _internalId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), keccak256(abi.encode(_items)), _internalId, HASH_SIGN));
    }
}