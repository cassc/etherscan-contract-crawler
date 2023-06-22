// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../storage/GenArtStorage.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtMinter.sol";
import "../factory/GenArtCollectionFactory.sol";
import "../factory/GenArtPaymentSplitterFactory.sol";

/**
 * @dev GEN.ART Curated
 * Admin of {GenArtCollectionFactory} and {GenArtPaymentSplitterFactory}
 */

struct CreateCollectionParams {
    address artist;
    string name;
    string symbol;
    string script;
    uint8 collectionType;
    uint256 maxSupply;
    uint8 erc721Index;
    uint8 pricingMode;
    bytes pricingData;
    uint8 paymentSplitterIndex;
    address[] payeesMint;
    address[] payeesRoyalties;
    uint256[] sharesMint;
    uint256[] sharesRoyalties;
}
struct PricingParams {
    uint8 mode;
    bytes data;
}

struct CollectionInfo {
    string name;
    string symbol;
    address minter;
    Collection collection;
    Artist artist;
}

contract GenArtCurated is GenArtAccess {
    address public collectionFactory;
    address public paymentSplitterFactory;
    GenArtStorage public store;
    mapping(uint8 => address) public minters;

    event ScriptUpdated(address collection, string script);

    constructor(
        address collectionFactory_,
        address paymentSplitterFactory_,
        address store_
    ) {
        collectionFactory = collectionFactory_;
        paymentSplitterFactory = paymentSplitterFactory_;
        store = GenArtStorage(payable(store_));
    }

    /**
     * @dev Internal functtion to close the ERC721 implementation contract
     */
    function _cloneCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        return
            GenArtCollectionFactory(collectionFactory).cloneCollectionContract(
                params
            );
    }

    /**
     * @dev Internal functtion to create the collection and risgister to minter
     */
    function _createCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        (instance, id) = _cloneCollection(params);
        store.setCollection(
            Collection(
                id,
                params.artist,
                instance,
                params.maxSupply,
                params.script,
                params.paymentSplitter
            )
        );
    }

    /**
     * @dev Clones an ERC721 implementation contract
     * @param params params
     * @dev artist address of artist
     * @dev name name of collection
     * @dev symbol ERC721 symbol for collection
     * @dev script single html as string
     * @dev maxSupply max token supply
     * @dev erc721Index ERC721 implementation index
     * @dev pricingMode minter index
     * @dev pricingData calldata for `setPricing` function
     * @dev payeesMint address list of payees of mint proceeds
     * @dev payeesRoyalties address list of payees of royalties
     * @dev sharesMint list of shares for mint proceeds
     * @dev sharesRoyalties list of shares for royalties
     * Note payee and shares indices must be in respective order
     */
    function createCollection(CreateCollectionParams calldata params)
        external
        onlyAdmin
    {
        address artistAddress = params.artist;
        address minter = minters[params.pricingMode];
        _createArtist(artistAddress);
        address paymentSplitter = GenArtPaymentSplitterFactory(
            paymentSplitterFactory
        ).clone(
                genartAdmin,
                artistAddress,
                params.paymentSplitterIndex,
                params.payeesMint,
                params.payeesRoyalties,
                params.sharesMint,
                params.sharesRoyalties
            );
        address instance = GenArtCollectionFactory(collectionFactory)
            .predictDeterministicAddress(params.erc721Index);
        uint256 price = IGenArtMinter(minter).setPricing(
            instance,
            params.pricingData
        );
        _createCollection(
            CollectionParams(
                artistAddress,
                params.name,
                params.symbol,
                price,
                params.script,
                params.collectionType,
                params.maxSupply,
                params.erc721Index,
                minter,
                paymentSplitter
            )
        );
    }

    /**
     * @dev Internal helper method to create artist
     * @param artist address of artist
     */
    function _createArtist(address artist) internal {
        if (store.getArtist(artist).wallet != address(0)) return;
        address[] memory collections_;
        store.setArtist(Artist(artist, collections_));
    }

    /**
     * @dev Set the {GenArtCollectionFactory} contract address
     */
    function setCollectionFactory(address factory) external onlyAdmin {
        collectionFactory = factory;
    }

    /**
     * @dev Set the {GenArtPaymentSplitterFactory} contract address
     */
    function setPaymentSplitterFactory(address factory) external onlyAdmin {
        paymentSplitterFactory = factory;
    }

    /**
     * @dev Add a minter contract and map by index
     */
    function addMinter(uint8 index, address minter) external onlyAdmin {
        minters[index] = minter;
    }

    /**
     * @dev Get collection info
     * @param collection contract address of the collection
     */
    function getCollectionInfo(address collection)
        external
        view
        returns (CollectionInfo memory info)
    {
        (
            string memory name,
            string memory symbol,
            address artist,
            address minter,
            ,
            ,

        ) = IGenArtERC721(collection).getInfo();
        Artist memory artist_ = store.getArtist(artist);

        info = CollectionInfo(
            name,
            symbol,
            minter,
            store.getCollection(collection),
            artist_
        );
    }
}