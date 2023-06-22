// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./interfaces/IDeedAuthorizer.sol";
import "./interfaces/IFPD.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "operator-filter-registry/src/upgradeable/RevokableDefaultOperatorFiltererUpgradeable.sol";

/// @title Fellowship Print Deeds
contract FellowshipPrintDeeds is 
    IFPD, RevokableDefaultOperatorFiltererUpgradeable, ERC2981, ERC1155Holder, ERC1155, Pausable, Ownable {

    string public constant name = "Fellowship Print Deeds";
    string public constant symbol = "FPD";


    mapping(address => CollectionInfo) private _collectionInfo;
    mapping(address => RoyaltyInfo) public collectionToRoyaltyInfo;
    mapping(uint256 => uint256) public deedsClaimed;

    address public printFactory = 0x11F32c8d5Ad08f844CA2E95f6ffE66E5Cd74457D;
    address public uriDelegate;

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Receiver, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ONLY OWNER FUNCTIONS

    /// @notice Add a new collection's deeds to the contract, token ids MUST be continuous and no larger than uint96
    /// @param collection The address of the collection to be added
    /// @param collectionStartId Lowest tokenId of collection, typically 0 or 1
    /// @param collectionSupply The supply of the collection
    /// @param editionSize The size of the edition
    /// @param royaltyRecipient The address of the recipient of the royalties
    /// @param authorizer The address of the contract handling claim authorization
    function addCollection(
        address collection,
        uint256 collectionStartId,
        uint256 collectionSupply,
        uint256 editionSize,
        address royaltyRecipient,
        address authorizer
    ) external onlyOwner {
        require(_collectionInfo[collection].editionSize == 0);
        require(editionSize > 0 && royaltyRecipient != address(0) && authorizer != address(0));
        uint256[] memory deedIds = new uint256[](collectionSupply);
        uint256[] memory amounts = new uint256[](collectionSupply);
        uint256 upperLimit = collectionStartId + collectionSupply;
        for (uint256 i = collectionStartId; i < upperLimit; ++i) {
            deedIds[i] = artTokentoDeedId(collection, i);
            amounts[i] = editionSize;
        }
        _collectionInfo[collection] = CollectionInfo(
            authorizer, uint96(collectionStartId), uint96(collectionSupply), uint96(editionSize)
        );
        updateRoyalties(collection, royaltyRecipient, 500);
        emit TransferBatch(msg.sender, address(0), address(this), deedIds, amounts);
    }

    /// @notice Create additional deeds by extending an exisiting collections total supply
    /// @param collection The address of the collection to extend
    /// @param additionalSupply The amount of tokens to add to the collection
    function extendCollection(
        address collection,
        uint256 additionalSupply
    ) external onlyOwner {
        CollectionInfo storage cInfo = _collectionInfo[collection];
        require(cInfo.editionSize > 0);
        uint256[] memory deedIds = new uint256[](additionalSupply);
        uint256[] memory amounts = new uint256[](additionalSupply);
        uint256 start = cInfo.startId + cInfo.supply;
        uint256 upperLimit = start + additionalSupply;
        uint256 editionSize = cInfo.editionSize;
        for (uint256 i = start; i < upperLimit; ++i) {
            deedIds[i] = artTokentoDeedId(collection, i);
            amounts[i] = editionSize;
        }
        cInfo.supply += uint96(additionalSupply);
        emit TransferBatch(msg.sender, address(0), address(this), deedIds, amounts);
    }

    /// @notice Create additional deeds for the existing supply of tokens of a collection
    /// @param collection The address of the collection to add editions to
    /// @param additionalEditions The amount of deeds to add
    function increaseEditions(
        address collection,
        uint256 additionalEditions
    ) external onlyOwner {
        CollectionInfo storage cInfo = _collectionInfo[collection];
        require(cInfo.editionSize > 0);
        uint256 supply = cInfo.supply;
        uint256[] memory deedIds = new uint256[](supply);
        uint256[] memory amounts = new uint256[](supply);
        uint256 start = cInfo.startId;
        uint256 upperLimit = start + supply;
        for (uint256 i = start; i < upperLimit; ++i) {
            deedIds[i] = artTokentoDeedId(collection, i);
            amounts[i] = additionalEditions;
        }
        cInfo.editionSize += uint96(additionalEditions);
        emit TransferBatch(msg.sender, address(0), address(this), deedIds, amounts);
    }

    /// @notice Pause claim functionality
    function pauseClaims() external onlyOwner {
        _pause();
    }

    /// @notice Unpause claim functionality
    function resumeClaims() external onlyOwner {
        _unpause();
    }

    /// @notice Update the authoriztion contract associated with a given collection
    /// @param collection The address of the collection to update
    /// @param authorizer The contract which manages claim permissions
    function updateCollectionAuth(
        address collection,
        address authorizer
    ) external onlyOwner {
        _collectionInfo[collection].authorizer = authorizer;
    }

    /// @notice Update the "Print Factory" address
    /// @param factory The cannonical address representing submission of a deed for printing
    function updatePrintFactory(
        address factory
    ) external onlyOwner {
        printFactory = factory;
    }

    function updateRoyalties(
        address collection,
        address recipient,
        uint256 royaltyBps
    ) public onlyOwner {
        collectionToRoyaltyInfo[collection] = RoyaltyInfo(recipient, uint96(royaltyBps));
    }

    function updateUriDelegate(
        address newUriDelegate
    ) external onlyOwner {
        uriDelegate = newUriDelegate;
    }

    // ERC2981 ROYALTIES

    /// @inheritdoc ERC2981
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view virtual override returns (address, uint256) {
        address collection = getCollectionFromDeedId(tokenId);
        RoyaltyInfo memory royalty = collectionToRoyaltyInfo[collection];

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    // CLAIM FUNCTIONALITY

    function claimDeeds(
        address[] calldata collections,
        uint256[] calldata ids
    ) external {
        _claim(collections, ids, msg.sender);
    }

    function claimDeedsTo(
        address[] calldata collections,
        uint256[] calldata ids,
        address to
    ) external {
        _claim(collections, ids, to);
    }

    function claimPrintsDirectly(
        address[] calldata collections,
        uint256[] calldata ids
    ) external {
        _claim(collections, ids, printFactory);
    }

    function claimDeedsPartial(
        address[] calldata collections,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        _claimPartial(collections, ids, amounts, msg.sender);
    }

    function claimDeedsPartialTo(
        address[] calldata collections,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to
    ) external {
        _claimPartial(collections, ids, amounts, to);
    }

    function claimPrintsDirectlyPartial(
        address[] calldata collections,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        _claimPartial(collections, ids, amounts, printFactory);
    }

    function _claim(
        address[] calldata collections,
        uint256[] calldata ids,
        address target
    ) internal whenNotPaused {
        require(collections.length == ids.length && collections.length > 0);
        uint256[] memory deedIds = new uint256[](collections.length);
        uint256[] memory amounts = new uint256[](collections.length);

        for (uint256 i; i < collections.length; ++i) {
            CollectionInfo memory cInfo = _collectionInfo[collections[i]];
            require(cInfo.editionSize > 0);
            require(ids[i] >= cInfo.startId && ids[i] < cInfo.startId + cInfo.supply);
            uint256 deedId = artTokentoDeedId(collections[i], ids[i]);
            uint256 deedsLeft = cInfo.editionSize - deedsClaimed[deedId];
            require(deedsLeft > 0);
            deedIds[i] = deedId;
            amounts[i] = deedsLeft;
            balanceOf[target][deedId] += deedsLeft;
            deedsClaimed[deedId] += deedsLeft;
            emit URI("", deedId);
            require(IDeedAuthorizer(
                cInfo.authorizer
            ).isAuthedForDeeds(msg.sender, collections[i], ids[i], amounts[i]));
        }

        emit TransferBatch(msg.sender, address(this), target, deedIds, amounts);
    }

    function _claimPartial(
        address[] calldata collections,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address target
    ) internal whenNotPaused {
        require(collections.length == ids.length && ids.length == amounts.length && collections.length > 0);
        uint256[] memory deedIds = new uint256[](collections.length);

        for (uint256 i; i < collections.length; ++i) {
            CollectionInfo memory cInfo = _collectionInfo[collections[i]];
            require(cInfo.editionSize > 0);
            require(ids[i] >= cInfo.startId && ids[i] < cInfo.startId + cInfo.supply);
            uint256 deedId = artTokentoDeedId(collections[i], ids[i]);
            require(amounts[i] > 0);
            require(amounts[i] <= cInfo.editionSize - deedsClaimed[deedId]);
            deedIds[i] = deedId;
            balanceOf[target][deedId] += amounts[i];
            deedsClaimed[deedId] += amounts[i];
            emit URI("", deedId);
            require(IDeedAuthorizer(
                cInfo.authorizer
            ).isAuthedForDeeds(msg.sender, collections[i], ids[i], amounts[i]));
        }

        emit TransferBatch(msg.sender, address(this), target, deedIds, amounts);
    }

    // HELPER FUNCTIONS

    function artTokentoDeedId(
        address collection,
        uint256 id
    ) public pure returns (uint256) {
        return (uint256(uint160(collection)) << 96) | uint96(id);
    }

    function collectionInfo(address collection) external view returns (CollectionInfo memory) {
        return _collectionInfo[collection];
    }

    function deedsLeftToClaim(
        address collection,
        uint256 id
    ) external view returns (uint256) {
        return _collectionInfo[collection].editionSize - deedsClaimed[artTokentoDeedId(collection, id)];
    }

    function getCollectionFromDeedId(
        uint256 deedId
    ) public pure returns (address) {
        return address(uint160(deedId >> 96));
    }

    function getArtTokenIdFromDeedId(
        uint256 deedId
    ) public pure returns (uint256) {
        return uint256(uint96(deedId));
    }

    /// @inheritdoc Ownable
    function owner() public view virtual override(Ownable, RevokableOperatorFiltererUpgradeable) returns (address) {
        return Ownable.owner();
    }

    // ERC1155 OVERRIDES

    /// @inheritdoc ERC1155
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc ERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
        if (to == printFactory) {
            emit URI("", tokenId);
        }
    }
    
    /// @inheritdoc ERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        if (to == printFactory) {
            for (uint256 i; i < ids.length; ++i) {
                emit URI("", ids[i]);
            }
        }
    }

    /// @inheritdoc ERC1155
    function uri(
        uint256 id
    ) public view override returns (string memory) {
        return ERC1155(uriDelegate).uri(id);
    }

    // UNCLAIM FUNCTIONALITY

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(
       address,
       address from,
       uint256 id,
       uint256 amount,
       bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == address(this));
        balanceOf[address(this)][id] = 0;
        deedsClaimed[id] -= amount;
        emit URI("", id);
        address collection = getCollectionFromDeedId(id);
        uint256 tokenId = getArtTokenIdFromDeedId(id);
        require(IDeedAuthorizer(_collectionInfo[collection].authorizer).deedsMerged(
            from,
            collection,
            tokenId,
            amount
        ));
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == address(this));
        for (uint256 i; i < ids.length; ++i) {
            balanceOf[address(this)][ids[i]] = 0;
            deedsClaimed[ids[i]] -= amounts[i];
            emit URI("", ids[i]);
            address collection = getCollectionFromDeedId(ids[i]);
            uint256 tokenId = getArtTokenIdFromDeedId(ids[i]);
            require(IDeedAuthorizer(_collectionInfo[collection].authorizer).deedsMerged(
                from,
                collection,
                tokenId,
                amounts[i]
            ));
        }
        return this.onERC1155BatchReceived.selector;
    }

    // PRINT FACTORY FUNCTIONALITY

    /// @notice Allow Print Factory address to burn deeds sent to it
    function burnDeeds(
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(msg.sender == printFactory);
        require(ids.length == amounts.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            balanceOf[msg.sender][ids[i]] -= amounts[i];
            balanceOf[address(0)][ids[i]] += amounts[i];
        }
        emit TransferBatch(msg.sender, msg.sender, address(0), ids, amounts);
    }
}