// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../factory/GenArtCollectionFactory.sol";
import "../factory/GenArtPaymentSplitterFactory.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtMinter.sol";

/**
 * @dev GEN.ART Curated
 * Admin of {GenArtCollectionFactory} and {GenArtPaymentSplitterFactory}
 */

contract GenArtCurated is GenArtAccess {
    struct Collection {
        uint256 id;
        address artist;
        address contractAddress;
        uint256 maxSupply;
        string script;
    }

    struct Artist {
        address wallet;
        address[] collections;
        address paymentSplitter;
    }

    struct CollectionInfo {
        string name;
        string symbol;
        address minter;
        Collection collection;
        Artist artist;
    }

    mapping(address => Collection) public collections;
    mapping(address => Artist) public artists;

    address public collectionFactory;
    address public paymentSplitterFactory;

    event ScriptUpdated(address collection, string script);

    constructor(address collectionFactory_, address paymentSplitterFactory_) {
        collectionFactory = collectionFactory_;
        paymentSplitterFactory = paymentSplitterFactory_;
    }

    /**
     * @dev Internal functtion to close the ERC721 implementation contract
     */
    function _cloneCollection(CollectionParams memory params)
        internal
        returns (address instance, uint256 id)
    {
        (instance, id) = GenArtCollectionFactory(collectionFactory)
            .cloneCollectionContract(params);
        collections[instance] = Collection(
            id,
            params.artist,
            instance,
            params.maxSupply,
            params.script
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
        address minter = GenArtCollectionFactory(collectionFactory).minters(
            params.minterIndex
        );
        IGenArtMinter(minter).addPricing(instance, params.artist);
    }

    /**
     * @dev Clones an ERC721 implementation contract
     * @param artist address of artist
     * @param name name of collection
     * @param symbol ERC721 symbol for collection
     * @param script single html as string
     * @param maxSupply max token supply
     * @param erc721Index ERC721 implementation index
     * @param minterIndex minter index
     */
    function createCollection(
        address artist,
        string memory name,
        string memory symbol,
        string memory script,
        bool hasOnChainScript,
        uint256 maxSupply,
        uint8 erc721Index,
        uint8 minterIndex
    ) external onlyAdmin {
        Artist storage artist_ = artists[artist];
        require(artist_.wallet != address(0), "artist does not exist");

        (address instance, ) = _createCollection(
            CollectionParams(
                artist,
                name,
                symbol,
                script,
                hasOnChainScript,
                maxSupply,
                erc721Index,
                minterIndex,
                artists[artist].paymentSplitter
            )
        );
        artist_.collections.push(instance);
    }

    /**
     * @dev Get all available mints for account
     * @param artist address of artist
     * @param payeesMint address list of payees of mint proceeds
     * @param payeesRoyalties address list of payees of royalties
     * @param sharesMint list of shares for mint proceeds
     * @param sharesRoyalties list of shares for royalties
     * Note payee and shares indices must be in respective order
     */
    function createArtist(
        address artist,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) external onlyAdmin {
        require(artists[artist].wallet == address(0), "already exists");
        address paymentSplitter = GenArtPaymentSplitterFactory(
            paymentSplitterFactory
        ).clone(
                genartAdmin,
                artist,
                payeesMint,
                payeesRoyalties,
                sharesMint,
                sharesRoyalties
            );
        address[] memory collections_;
        artists[artist] = Artist(artist, collections_, paymentSplitter);
    }

    /**
     * @dev Helper function to get {PaymentSplitter} of artist
     */
    function getPaymentSplitterForCollection(address collection)
        external
        view
        returns (address)
    {
        return artists[collections[collection].artist].paymentSplitter;
    }

    /**
     * @dev Get artist struct
     * @param artist adress of artist
     */
    function getArtist(address artist) external view returns (Artist memory) {
        return artists[artist];
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
        Artist memory artist_ = artists[artist];

        info = CollectionInfo(
            name,
            symbol,
            minter,
            collections[collection],
            artist_
        );
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
     * @dev Update script of collection
     * @param collection contract address of the collection
     * @param script single html as string
     */
    function updateScript(address collection, string memory script) external {
        address sender = _msgSender();
        require(
            collections[collection].artist == sender ||
                admins[sender] ||
                owner() == sender,
            "not allowed"
        );
        collections[collection].script = script;
        emit ScriptUpdated(collection, script);
    }
}