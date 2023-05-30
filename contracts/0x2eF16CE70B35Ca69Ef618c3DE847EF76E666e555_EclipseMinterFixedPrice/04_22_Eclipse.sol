// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {EclipseAccess} from "../access/EclipseAccess.sol";
import {EclipseCollectionFactory, CollectionParams} from "../factory/EclipseCollectionFactory.sol";
import {EclipsePaymentSplitterFactory} from "../factory/EclipsePaymentSplitterFactory.sol";
import {IEclipseERC721} from "../interface/IEclipseERC721.sol";
import {IEclipseMinter} from "../interface/IEclipseMinter.sol";
import {EclipseStorage, Collection, Artist} from "../storage/EclipseStorage.sol";

/**
 * @dev Eclipse
 * Admin of {EclipseCollectionFactory} and {EclipsePaymentSplitterFactory}
 */

struct CreateCollectionParams {
    string name;
    string symbol;
    string script;
    uint8 collectionType;
    uint24 maxSupply;
    uint8 erc721Index;
    uint8[] pricingMode;
    bytes[] pricingData;
    address[] payeesMint;
    address[] payeesRoyalties;
    uint24[] sharesMint;
    uint24[] sharesRoyalties;
}
struct PricingParams {
    uint8 mode;
    bytes data;
}

struct CollectionInfo {
    string name;
    string symbol;
    Collection collection;
    Artist artist;
}

contract Eclipse is EclipseAccess {
    address public collectionFactory;
    address public paymentSplitterFactory;
    address public platformPayoutAddress;
    mapping(uint8 => address) public minters;
    mapping(uint8 => address) public gateTypes;

    EclipseStorage public store;

    constructor(
        address collectionFactory_,
        address paymentSplitterFactory_,
        address store_,
        address platformPayoutAddress_
    ) {
        collectionFactory = collectionFactory_;
        paymentSplitterFactory = paymentSplitterFactory_;
        platformPayoutAddress = platformPayoutAddress_;
        store = EclipseStorage(store_);
    }

    /**
     * @dev Throws if called by any account other than the artist
     */
    modifier onlyArtist(address collection) {
        address artist = store.getCollection(collection).artist;
        require(
            _msgSender() == artist,
            "EclipseAccess: caller is not the artist"
        );
        _;
    }

    /**
     * @dev Internal functtion to close the ERC721 implementation contract
     */
    function _cloneCollection(
        CollectionParams memory params
    ) internal returns (address instance, uint256 id) {
        return
            EclipseCollectionFactory(collectionFactory).cloneCollectionContract(
                params
            );
    }

    /**
     * @dev Internal functtion to create the collection and risgister to minter
     */
    function _createCollection(
        CollectionParams memory params
    ) internal returns (address instance, uint256 id) {
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
    function createCollection(CreateCollectionParams calldata params) external {
        uint24 maxSupply = params.maxSupply;
        require(maxSupply <= 1_000_000, "maxSupply too big");
        address artist = _msgSender();
        _createArtist(artist);
        address paymentSplitter = EclipsePaymentSplitterFactory(
            paymentSplitterFactory
        ).clone(
                owner(),
                platformPayoutAddress,
                artist,
                params.payeesMint,
                params.payeesRoyalties,
                params.sharesMint,
                params.sharesRoyalties
            );
        address instance = EclipseCollectionFactory(collectionFactory)
            .predictDeterministicAddress(params.erc721Index);
        bytes[] memory pricingData = params.pricingData;
        uint8[] memory pricingMode = params.pricingMode;
        address[] memory collectionMinters = new address[](pricingMode.length);
        for (uint8 i; i < pricingMode.length; i++) {
            address minter = minters[pricingMode[i]];
            collectionMinters[i] = minter;
            _addMinterToCollection(instance, artist, minter, pricingData[i]);
        }
        _createCollection(
            CollectionParams(
                artist,
                params.name,
                params.symbol,
                params.script,
                params.collectionType,
                maxSupply,
                address(this),
                params.erc721Index,
                collectionMinters,
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
     * @dev Internal helper method to add minter to collection
     */
    function _addMinterToCollection(
        address collection,
        address sender,
        address minter,
        bytes memory pricingData
    ) internal {
        IEclipseMinter(minter).setPricing(collection, sender, pricingData);
    }

    /**
     * @dev Set the {EclipseCollectionFactory} contract address
     */
    function setCollectionFactory(address factory) external onlyAdmin {
        collectionFactory = factory;
    }

    /**
     * @dev Set the {EclipsePaymentSplitterFactory} contract address
     */
    function setPaymentSplitterFactory(address factory) external onlyAdmin {
        paymentSplitterFactory = factory;
    }

    /**
     * @dev Set the {EclipsePaymentSplitterFactory} contract address
     */
    function enableMinterForCollection(
        address collection,
        uint8 pricingMode,
        bytes memory pricingData,
        bool enable
    ) external onlyArtist(collection) {
        address minter = minters[pricingMode];
        if (enable) {
            _addMinterToCollection(
                collection,
                _msgSender(),
                minter,
                pricingData
            );
        }
        IEclipseERC721(collection).setMinter(minter, enable);
    }

    /**
     * @dev Add a minter contract and map by index
     */
    function addMinter(uint8 index, address minter) external onlyAdmin {
        minters[index] = minter;
    }

    /**
     * @dev Add a gatre contract and map by index
     */
    function addGate(uint8 index, address gate) external onlyAdmin {
        gateTypes[index] = gate;
    }

    /**
     * @dev Get collection info
     * @param collection contract address of the collection
     */
    function getCollectionInfo(
        address collection
    ) external view returns (CollectionInfo memory info) {
        (
            string memory name,
            string memory symbol,
            address artist,
            ,
            ,

        ) = IEclipseERC721(collection).getInfo();
        Artist memory artist_ = store.getArtist(artist);

        info = CollectionInfo(
            name,
            symbol,
            store.getCollection(collection),
            artist_
        );
    }
}