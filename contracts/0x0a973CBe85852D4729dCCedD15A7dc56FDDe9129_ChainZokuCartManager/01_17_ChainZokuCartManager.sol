// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IChainzokuItem.sol";
import "./libs/interfaces/IStoreNFT.sol";
import "./libs/interfaces/IERC1155Proxy.sol";
import "./libs/Signature.sol";
import "./libs/Initialize.sol";
import "./libs/Pause.sol";

// @author: miinded.com

contract ChainZokuCartManager is IChainzokuItem, Initialize, Signature, ReentrancyGuard, Pause {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private internalIdFlagged;
    address public storedNftContract;

    function init(
        address _storedNftContract,
        address _signAddress
    ) public onlyOwner isNotInitialized {
        storedNftContract = _storedNftContract;
        Signature.setSignAddress(_signAddress);
        Signature.setHashSign(3345547);
    }

    function MintItems(
        CollectionItems[] memory _collectionItems,
        uint256 _internalId,
        bytes memory _signature
    )
    public notPaused signedUnique(_mintCollectionItemsValid(_collectionItems, _internalId), _internalId, _signature) nonReentrant {
        for (uint256 i = 0; i < _collectionItems.length; i++) {
            _mintItems(_collectionItems[i]);
        }
    }

    function _mintItems(CollectionItems memory _collectionItem) internal {
        require(_collectionItem.ids.length == _collectionItem.counts.length, "ChainZokuCartManager: ids,counts length mismatch");

        uint256 totalCount = 0;
        for(uint256 i = 0; i < _collectionItem.counts.length; i++){
            totalCount += _collectionItem.counts[i];
        }
        require(_collectionItem.internalIds.length == totalCount, "ChainZokuCartManager: internalIds length mismatch");

        for (uint256 i = 0; i < _collectionItem.internalIds.length; i++) {
            _flagInternalId(_collectionItem.internalIds[i]);
        }

        if (_collectionItem.action == Action.Mint) {
            IERC1155Proxy(_collectionItem.collection).mintBatch(_msgSender(), _collectionItem.ids, _collectionItem.counts);
        }

        if (_collectionItem.action == Action.Transfer) {
            IStoreNFT(storedNftContract).TransferBatchExternal(_msgSender(), _collectionItem.collection, _collectionItem.ids, _collectionItem.counts);
        }

        emit FlagItems(_collectionItem.internalIds, uint8(_collectionItem.action), 0);
    }

    function _flagInternalId(uint256 _internalId) internal {
        require(internalIdFlagged.get(_internalId) == false, "ChainZokuCartManager: internalId already flag");
        internalIdFlagged.set(_internalId);
    }

    function _mintCollectionItemsValid(CollectionItems[] memory _items, uint256 _internalId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), keccak256(abi.encode(_items)), _internalId, HASH_SIGN));
    }

    function setStoredNftContract(address _storedNftContract) public onlyOwnerOrAdmins {
        storedNftContract = _storedNftContract;
    }
}