// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title INFTBuyer
 * @author pbnather
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTBuyer {
    /* ============ Events ============ */

    event CollectionAdded(
        IERC721 indexed _collection,
        IERC20 _token,
        uint256 _price,
        uint256[] _ids
    );

    event CollectionIdsSet(
        IERC721 indexed _collection,
        uint256[] _ids,
        bool[] _allows
    );

    event CollectionAllowAllChanged(
        IERC721 indexed _collection,
        bool _allowAll
    );

    event CollectionPriceAndTokenChanged(
        IERC721 indexed _collection,
        uint256 _price,
        IERC20 _token
    );

    event NFTReceiverChanged(
        address indexed _oldNftReceiver,
        address indexed _newNftReceiver
    );

    event WithdrewTokens(IERC20 indexed _token, uint256 amount);

    event Redeemed(
        IERC721 indexed _collection,
        uint256 indexed _id,
        address indexed _user
    );

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
    ) external;

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
    ) external;

    /**
     * @notice Set collection's `allowAll` state, if all ids are allowed.
     *
     * @dev Setting `allowAll` to true will clear `allowedList` and `allowed`.
     *
     * @param _collection Address of ERC721 collection.
     * @param _allowAll New `allowAll` state.
     */
    function setCollectionAllowAll(IERC721 _collection, bool _allowAll)
        external;

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
    ) external;

    /**
     * @notice Set address that gets all the NFTs.
     *
     * @param _nftReceiver Address that gets all the NFTs.
     */
    function setNftReceiver(address _nftReceiver) external;

    /**
     * @notice Withdraws ERC20 token to the owner address.
     *
     * @param _token ERC20 token address to withdraw.
     */
    function withdrawTokens(IERC20 _token) external;

    /* ============ External Functions ============ */

    /**
     * @notice Redeem NFTs for the corresponding ERC20 tokens.
     *
     * @dev Will revert if any NFT won't redeem succesfully.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of ids to redeem.
     */
    function redeem(IERC721 _collection, uint256[] memory _ids) external;

    /* ============ External View Functions ============ */

    /**
     * @notice Returns length of the `collections` list.
     *
     * @dev First Collection is dummy one.
     *
     * @return length_ Length of the `collections` list.
     */
    function getCollectionsLength() external view returns (uint256 length_);

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
        returns (address[] memory collections_);

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
        returns (bool allIds_, uint256[] memory ids_);

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
        returns (IERC20 token_, uint256 price_);

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
        returns (bool allowed_);

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
        returns (uint256[] memory ids_);
}