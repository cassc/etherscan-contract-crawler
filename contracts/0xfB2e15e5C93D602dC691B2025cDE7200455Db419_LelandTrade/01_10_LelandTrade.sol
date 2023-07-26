// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/ILelandTrade.sol";

contract LelandTrade is ERC721Holder, Ownable, ILelandTrade {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public merkleRoot;
    mapping(uint16 => EnumerableSet.UintSet) private depositedTokenIdsPerRarity;
    mapping(uint256 => uint16) private depositedRarityByTokenIds;

    address public lelandNFT;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint16 public topRarity;

    uint16 public duplicateAmountForUpgrade;

    uint16 public duplicateAmountForTrade;

    constructor(
        address _lelandNFT,
        uint16 _duplicateAmountForUpgrade,
        uint16 _duplicateAmountForTrade,
        uint16 _topRarity
    ) {
        require(_lelandNFT != address(0), "zero LelandNFT address");
        require(
            _duplicateAmountForUpgrade != 0 && _duplicateAmountForTrade != 0,
            "invalid upgrade amount"
        );
        require(_topRarity > 1, "invalid topRarity");
        duplicateAmountForUpgrade = _duplicateAmountForUpgrade;
        duplicateAmountForTrade = _duplicateAmountForTrade;
        lelandNFT = _lelandNFT;
        topRarity = _topRarity;
    }

    /// @inheritdoc ILelandTrade
    function resetInits(
        uint16 _duplicateAmountForUpgrade,
        uint16 _duplicateAmountForTrade,
        uint16 _topRarity
    ) external override onlyOwner {
        require(
            _duplicateAmountForUpgrade != 0 && _duplicateAmountForTrade != 0,
            "invalid upgrade amount"
        );
        require(_topRarity > 1, "invalid topRarity");
        duplicateAmountForUpgrade = _duplicateAmountForUpgrade;
        duplicateAmountForTrade = _duplicateAmountForTrade;
        topRarity = _topRarity;

        emit ResetInit(
            _duplicateAmountForUpgrade,
            _duplicateAmountForTrade,
            _topRarity
        );
    }

    /// @inheritdoc ILelandTrade
    function setRoot(bytes32 _root) payable external override onlyOwner {
        merkleRoot = _root;
    }

    /// @inheritdoc ILelandTrade
    function depositCollection(CollectionInfo[] memory _depositCollections)
        external
        override
        onlyOwner
    {
        address sender = msg.sender;
        uint256 length = _depositCollections.length;
        require(length != 0, "invalid length array");
        for (uint256 i = 0; i < length; ++i) {
            CollectionInfo memory info = _depositCollections[i];
            require(
                _verifyTokenInfo(
                    info.proof,
                    info.tokenId,
                    info.cardNo,
                    info.rarityId
                ),
                "invalid info"
            );
            IERC721(lelandNFT).safeTransferFrom(
                sender,
                address(this),
                info.tokenId
            );
            depositedTokenIdsPerRarity[info.rarityId].add(info.tokenId);
            depositedRarityByTokenIds[info.tokenId] = info.rarityId;
        }

        emit CollectionDeposited(_depositCollections);
    }

    /// @inheritdoc ILelandTrade
    function withdrawCollection(uint256[] memory _tokenIds)
        external
        override
        onlyOwner
    {
        uint256 length = _tokenIds.length;
        require(length != 0, "invalid length array");

        for (uint256 i = 0; i < length; ++i) {
            uint256 tokenId = _tokenIds[i];
            uint16 rarity = depositedRarityByTokenIds[tokenId];
            require(
                depositedTokenIdsPerRarity[rarity].contains(tokenId),
                "not deposited tokenId"
            );
            depositedTokenIdsPerRarity[rarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionWithdrawn(_tokenIds);
    }

    /// @inheritdoc ILelandTrade
    function upgradeCollectionForCertainCollection(
        CollectionInfo[] memory _collections,
        uint256[] memory _targetTokenIds,
        bool _upgradeMode
    ) external override {
        if (_upgradeMode) {
            _upgradeCollectionForCertainCollectionUpgradeMode(
                _collections,
                _targetTokenIds
            );
        } else {
            _upgradeCollectionForCertainCollectionTradeMode(
                _collections,
                _targetTokenIds
            );
        }
    }

    function _upgradeCollectionForCertainCollectionUpgradeMode(
        CollectionInfo[] memory _collections,
        uint256[] memory _targetTokenIds
    ) internal {
        (uint16 returnedRarity, uint256 upgradeCollectionCnt) = _checkCollectionUpgradeMode(
            _collections
        );
        require(returnedRarity < topRarity, "fail");
        require(
            upgradeCollectionCnt == _targetTokenIds.length,
            "Invalid targetTokenIds array length"
        );

        for (uint256 i = 0; i < _targetTokenIds.length; ++i) {
            uint256 tokenId = _targetTokenIds[i];
            require(
                depositedTokenIdsPerRarity[returnedRarity].contains(tokenId),
                "invalid target collection"
            );
            depositedTokenIdsPerRarity[returnedRarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionUpgradedWithCertainCollection(
            _collections,
            _targetTokenIds,
            true
        );
    }

    function _upgradeCollectionForCertainCollectionTradeMode(
        CollectionInfo[] memory _collections,
        uint256[] memory _targetTokenIds
    ) internal {
        (uint16 returnedRarity, uint256 tradeCollectionCnt) = _checkCollectionTradeMode(
            _collections
        );
        require(returnedRarity < topRarity, "fail");
        require(
            tradeCollectionCnt == _targetTokenIds.length,
            "Invalid targetTokenIds array length"
        );

        for (uint256 i = 0; i < _targetTokenIds.length; ++i) {
            uint256 tokenId = _targetTokenIds[i];
            require(
                depositedTokenIdsPerRarity[returnedRarity].contains(tokenId),
                "invalid target collection"
            );
            depositedTokenIdsPerRarity[returnedRarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionUpgradedWithCertainCollection(
            _collections,
            _targetTokenIds,
            false
        );
    }
    
    /// @inheritdoc ILelandTrade
    function upgradeCollection(
        CollectionInfo[] memory _collections,
        bool _upgradeMode
    ) external override {
        if (_upgradeMode) {
            _upgradeCollectionUpgradeMode(_collections);
        } else {
            _upgradeCollectionTradeMode(_collections);
        }
    }

    function _upgradeCollectionUpgradeMode(
        CollectionInfo[] memory _collections
    ) internal {
        (uint16 returnedRarity, uint256 upgradeCollectionCnt) = _checkCollectionUpgradeMode(
            _collections
        );
        require(returnedRarity < topRarity, "fail");

        uint256[] memory tokenIds = depositedTokenIdsPerRarity[returnedRarity]
            .values();
        for (uint256 i = 0; i < upgradeCollectionCnt; ++i) {
            uint256 tokenId = tokenIds[i];
            depositedTokenIdsPerRarity[returnedRarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionUpgraded(_collections, true);
    }

    function _upgradeCollectionTradeMode(
        CollectionInfo[] memory _collections
    ) internal {
        (uint16 returnedRarity, uint256 tradeCollectionCnt) = _checkCollectionTradeMode(
            _collections
        );
        require(returnedRarity < topRarity, "fail");

        uint256[] memory tokenIds = depositedTokenIdsPerRarity[returnedRarity]
            .values();
        for (uint256 i = 0; i < tradeCollectionCnt; ++i) {
            uint256 tokenId = tokenIds[i];
            depositedTokenIdsPerRarity[returnedRarity].remove(tokenId);
            IERC721(lelandNFT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        emit CollectionUpgraded(_collections, false);
    }

    function _checkCollectionUpgradeMode(CollectionInfo[] memory _collections)
        internal
        returns (uint16, uint256)
    {
        uint256 length = _collections.length;
        require(length != 0, "invalid length array");

        uint16 originRarity = _collections[0].rarityId;
        uint16 originCardId = _collections[0].cardNo;
        require(originRarity < topRarity, "last rarity");

        uint256 upgradeCollectionCnt = length / duplicateAmountForUpgrade;
        require(
            upgradeCollectionCnt != 0,
            "not enough collection for upgrade"
        );

        require(
            depositedTokenIdsPerRarity[originRarity + 1].length() >=
                upgradeCollectionCnt,
            "not enough upgradeable collection"
        );

        require(
            length % duplicateAmountForUpgrade == 0,
            "incorrect upgrade amount"
        );

        _processCollections(_collections, length, originRarity, originCardId);

        return (originRarity + 1, upgradeCollectionCnt);
    }

    function _checkCollectionTradeMode(CollectionInfo[] memory _collections)
        internal
        returns (uint16, uint256)
    {
        uint256 length = _collections.length;
        require(length != 0, "invalid length array");

        uint16 originRarity = _collections[0].rarityId;
        uint16 originCardId = _collections[0].cardNo;
        require(originRarity < topRarity, "last rarity");

        uint256 tradeCollectionCnt = length / duplicateAmountForTrade;
        require(
            tradeCollectionCnt != 0,
            "not enough collection for trade"
        );

        require(
            depositedTokenIdsPerRarity[originRarity].length() >=
                tradeCollectionCnt,
            "not enough tradeable collection"
        );

        require(
            length % duplicateAmountForTrade == 0,
            "incorrect trade amount"
        );

        _processCollections(_collections, length, originRarity, originCardId);

        return (originRarity, tradeCollectionCnt);
    }

    function _processCollections(
        CollectionInfo[] memory _collections,
        uint256 length,
        uint16 originRarity,
        uint16 originCardId
    ) internal {
        for (uint256 i = 0; i < length; ++i) {
            CollectionInfo memory info = _collections[i];
            require(
                originRarity == info.rarityId,
                "rarity type should be same"
            );
            require(
                info.cardNo == originCardId,
                "collection cardId should be same"
            );
            require(
                _verifyTokenInfo(
                    info.proof,
                    info.tokenId,
                    info.cardNo,
                    info.rarityId
                ),
                "invalid collection info"
            );

            IERC721(lelandNFT).safeTransferFrom(
                msg.sender,
                DEAD,
                info.tokenId
            );
        }
    }

    function getDepositedTokenIdsByRarity(
        uint16 _rarityId
    ) external view override returns (uint256[] memory) {
        return depositedTokenIdsPerRarity[_rarityId].values();
    }

    function _verifyTokenInfo(
        bytes32[] memory _proof,
        uint256 _tokenId,
        uint16 _cardNo,
        uint16 _rarityId
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encode(_tokenId, _rarityId, _cardNo)
        );
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }
}