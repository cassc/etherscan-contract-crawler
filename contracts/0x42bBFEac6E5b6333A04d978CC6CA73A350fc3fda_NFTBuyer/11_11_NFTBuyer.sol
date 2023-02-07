// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title NFTBuyer
 * @author pbnather
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./interfaces/INFTBuyer.sol";

contract NFTBuyer is INFTBuyer, Ownable {
    using SafeERC20 for IERC20;

    /* ============ Structures ============ */

    struct Collection {
        IERC721 collectionAddress;
        IERC20 payoutToken;
        uint256 price;
        bool allowAll;
        mapping(uint256 => bool) allowed;
        uint256[] allowedList;
    }

    /* ============ State ============ */

    Collection[] public collections;
    mapping(address => uint256) public collectionIndexes;
    address public nftReceiver;

    /* ============ Constructor ============ */

    constructor(address _nftReceiver) {
        require(_nftReceiver != address(0));
        nftReceiver = _nftReceiver;
        collections.push();
    }

    /* ============ External Owner Functions ============ */

    /**
     * @notice Adds collection with specific ids, or all ids allowlisted.
     *
     * @dev If @param _allowAll is set to true, @param _ids has to be empty.
     * If @param _allowAll is set to false, @param _ids cannot be empty.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of allowlisted ids.
     * @param _allowAll Bool if all ids are allowlisted.
     * @param _token ERC20 token address that is paid for NFTs in the collection.
     * @param _price Price of the NFT in @param _token.
     */
    function addCollection(
        IERC721 _collection,
        uint256[] memory _ids,
        bool _allowAll,
        IERC20 _token,
        uint256 _price
    ) external onlyOwner {
        uint256 length = _ids.length;
        if (_allowAll) require(length == 0, "_allowAll is true, don't add ids");
        else require(length > 0, "_allowAll is false, specify ids");
        require(address(_token) != address(0), "Token address zero");
        require(address(_collection) != address(0), "Collection address zero");
        require(
            collectionIndexes[address(_collection)] == 0,
            "Collection already exists"
        );
        require(_price > 0, "Price is zero");

        collections.push();
        uint256 index = collections.length - 1;
        collectionIndexes[address(_collection)] = index;
        Collection storage collection = collections[index];
        collection.collectionAddress = _collection;
        collection.payoutToken = _token;
        collection.price = _price;
        collection.allowAll = _allowAll;
        for (uint256 i = 0; i < length; i++) {
            collection.allowed[_ids[i]] = true;
            collection.allowedList.push(_ids[i]);
        }

        emit CollectionAdded(_collection, _token, _price, _ids);
    }

    /**
     * @notice Set collection ids' state.
     *
     * @dev Collection's `allowAll` has to be false.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of collection ids.
     * @param _allows List of ids' allowed states in same order as @param _ids.
     */
    function setCollectionIds(
        IERC721 _collection,
        uint256[] memory _ids,
        bool[] memory _allows
    ) external onlyOwner {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        require(collection.allowAll != true, "Collection is in allAllow mode");
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; i++) {
            if (collection.allowed[_ids[i]] == _allows[i]) continue;
            collection.allowed[_ids[i]] = _allows[i];
            if (_allows[i]) collection.allowedList.push(_ids[i]);
            else _deleteIdFromCollection(collection, _ids[i]);
        }

        emit CollectionIdsSet(_collection, _ids, _allows);
    }

    /**
     * @notice Set collection's `allowAll` state, if all ids are allowed.
     *
     * @dev Setting `allowAll` to true will clear `allowedList` and `allowed`.
     *
     * @param _collection Address of ERC721 collection.
     * @param _allowAll New `allowAll` state.
     */
    function setCollectionAllowAll(IERC721 _collection, bool _allowAll)
        external
        onlyOwner
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        require(collection.allowAll != _allowAll, "State is same");
        collection.allowAll = _allowAll;
        if (_allowAll) {
            uint256 length = collection.allowedList.length;
            for (uint256 i = 0; i < length; i++) {
                collection.allowed[collection.allowedList[i]] = false;
            }
            delete collection.allowedList;
        }
        emit CollectionAllowAllChanged(_collection, _allowAll);
    }

    /**
     * @notice Set collection's price per NFT and ERC20 token to payout.
     *
     * @param _collection Address of ERC721 collection.
     * @param _price Price of the NFT in @param _token.
     * @param _token ERC20 token address that is paid for NFTs in the collection.
     */
    function setCollectionPriceAndToken(
        IERC721 _collection,
        uint256 _price,
        IERC20 _token
    ) external onlyOwner {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        require(_price > 0, "Price is zero");
        require(address(_token) != address(0), "Token is address zero");
        collection.price = _price;
        collection.payoutToken = _token;
        emit CollectionPriceAndTokenChanged(_collection, _price, _token);
    }

    /**
     * @notice Set address that gets all the NFTs.
     *
     * @param _nftReceiver Address that gets all the NFTs.
     */
    function setNftReceiver(address _nftReceiver) external onlyOwner {
        require(_nftReceiver != address(0), "New address is address zero");
        require(_nftReceiver != nftReceiver, "Address is same");
        address oldNftReceiver = nftReceiver;
        nftReceiver = _nftReceiver;
        emit NFTReceiverChanged(oldNftReceiver, _nftReceiver);
    }

    /**
     * @notice Withdraws ERC20 token to the owner address.
     *
     * @param _token ERC20 token address to withdraw.
     */
    function withdrawTokens(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Token is address zero");
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "Cannot withdraw zero tokens");
        _token.safeTransfer(owner(), amount);
        emit WithdrewTokens(_token, amount);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Redeem NFTs for the corresponding ERC20 tokens.
     *
     * @dev Will revert if any NFT won't redeem succesfully.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of ids to redeem.
     */
    function redeem(IERC721 _collection, uint256[] memory _ids) external {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        for (uint256 i = 0; i < _ids.length; i++) {
            if (collection.allowAll || collection.allowed[_ids[i]]) {
                _redeemNft(collection, _ids[i]);
            } else {
                revert("NFT is not allowed");
            }
        }
    }

    /* ============ External View Functions ============ */

    /**
     * @notice Returns length of the `collections` list.
     *
     * @dev First Collection is dummy one.
     *
     * @return length_ Length of the `collections` list.
     */
    function getCollectionsLength() external view returns (uint256 length_) {
        length_ = collections.length;
    }

    /**
     * @notice Returns list of all collection addresses.
     *
     * @dev First dummy collection is ommited from the returned list.
     *
     * @return collections_ List of collection addresses.
     */
    function getAllCollectionAddresses()
        external
        view
        returns (address[] memory collections_)
    {
        uint256 length = collections.length;
        collections_ = new address[](length - 1);
        for (uint256 i = 1; i < length; i++) {
            collections_[i - 1] = address(collections[i].collectionAddress);
        }
    }

    /**
     * @notice Returns all allowed ids from the given collection.
     *
     * @dev If @return allIds_ is true, all ids are allowed, and @return ids_ is empty.
     *
     * @param _collection Address of ERC721 collection.
     *
     * @return allIds_ Bool if all ids are allowlisted.
     * @return ids_ List of allowed ids.
     */
    function getAllowedCollectionIds(IERC721 _collection)
        external
        view
        returns (bool allIds_, uint256[] memory ids_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        if (collection.allowAll) allIds_ = true;
        else {
            allIds_ = false;
            uint256 length = collection.allowedList.length;
            ids_ = new uint256[](length);
            for (uint256 i = 0; i < length; i++) {
                ids_[i] = collection.allowedList[i];
            }
        }
    }

    /**
     * @notice Returns price in ERC20 token for each NFT in the collection.
     *
     * @param _collection Address of ERC721 collection.
     *
     * @return token_ ERC20 token address that is paid for NFTs in the collection.
     * @return price_ Price of the NFT in @param _token.
     */
    function getCollectionPriceAndToken(IERC721 _collection)
        external
        view
        returns (IERC20 token_, uint256 price_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        token_ = collection.payoutToken;
        price_ = collection.price;
    }

    /**
     * @notice Returns if the given NFT id is allowlisted to redeem.
     *
     * @param _collection Address of ERC721 collection.
     * @param _id Id of the NFT in the @param _collection.
     *
     * @return allowed_ Bool if NFT with id @param _id is allowed.
     */
    function isNftAllowed(IERC721 _collection, uint256 _id)
        external
        view
        returns (bool allowed_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        if (collection.allowAll) {
            allowed_ = true;
        } else if (collection.allowed[_id]) {
            allowed_ = true;
        } else {
            allowed_ = false;
        }
    }

    /**
     * @notice Returns list of NFT collection id's that the user has and are able to redeem.
     *
     * @dev Collection has to support IERC721Enumerable for this to work, otherwise it will revert.
     *
     * @param _collection Address of ERC721 collection.
     * @param _account User account address to check.
     *
     * @return ids_ List of collection IDs that the user has and that are allowed to redeem.
     */
    function getUserAllowedNfts(IERC721 _collection, address _account)
        external
        view
        returns (uint256[] memory ids_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collectionInfo = collections[index];

        // Return empty array if user doesn't have nfts.
        uint256 nftBalance = _collection.balanceOf(_account);
        if (nftBalance == 0) return new uint256[](0);

        // Check if collection supports IERC721Enumerable extension.
        require(
            _collection.supportsInterface(type(IERC721Enumerable).interfaceId),
            "Collection not IERC721Enumerable"
        );

        IERC721Enumerable collection = IERC721Enumerable(address(_collection));
        uint256[] memory userNfts = new uint256[](nftBalance);

        if (collectionInfo.allowAll) {
            // Return all user NFTs.
            for (uint256 i = 0; i < nftBalance; i++) {
                userNfts[i] = collection.tokenOfOwnerByIndex(_account, i);
            }
            return userNfts;
        } else {
            // Filter NFTs to return.
            uint256 noAllowedIds = 0;
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 id = collection.tokenOfOwnerByIndex(_account, i);
                if (collectionInfo.allowed[id]) {
                    userNfts[noAllowedIds] = id;
                    noAllowedIds += 1;
                }
            }
            uint256[] memory userAllowedNfts = new uint256[](noAllowedIds);
            for (uint256 i = 0; i < noAllowedIds; i++) {
                userAllowedNfts[i] = userNfts[i];
            }
            return userAllowedNfts;
        }
    }

    /* ============ Private Functions ============ */

    /**
     * @dev Transfer tokens and NFTs, clear collections data if needed.
     *
     * @param _collection Collection struct from `collections` list.
     * @param _id Id of the NFT in the @param _collection.
     */
    function _redeemNft(Collection storage _collection, uint256 _id) private {
        require(
            _collection.payoutToken.balanceOf(address(this)) >=
                _collection.price,
            "Not enough tokens in the contract"
        );
        if (!_collection.allowAll) {
            _collection.allowed[_id] = false;
            _deleteIdFromCollection(_collection, _id);
        }
        _collection.collectionAddress.transferFrom(
            msg.sender,
            nftReceiver,
            _id
        );
        _collection.payoutToken.safeTransfer(msg.sender, _collection.price);
        emit Redeemed(_collection.collectionAddress, _id, msg.sender);
    }

    /**
     * @dev Deletes id from collection metadata
     *
     * @param _collection Collection struct from `collections` list.
     * @param _id Id of the NFT in the @param _collection.
     */
    function _deleteIdFromCollection(
        Collection storage _collection,
        uint256 _id
    ) private {
        for (uint256 i = 0; i < _collection.allowedList.length; i++) {
            if (_collection.allowedList[i] == _id) {
                _collection.allowedList[i] = _collection.allowedList[
                    _collection.allowedList.length - 1
                ];
                _collection.allowedList.pop();
                break;
            }
        }
    }
}