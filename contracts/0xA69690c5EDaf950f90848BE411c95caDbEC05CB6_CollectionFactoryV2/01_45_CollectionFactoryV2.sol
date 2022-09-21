// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./CollectionV2.sol";

/**
 * @title CollectionFactory
 * @notice This function will create new Upgradeable collection
 * @dev Upgradable Factory contract to create Upgradeable collections contract
 */
contract CollectionFactoryV2 is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _proxyIdCounter;

    // Mapping to store collection created by user
    // sender => list of collection Id deployed
    mapping(address => uint256[]) public _userCollections;
    // Mapping to store collection address
    // Collection Id => collection address
    mapping(uint256 => address) public _collections;

    // Events:
    event CollectionCreated(
        address indexed creator,
        address indexed collection,
        string name,
        string indexed symbol,
        string _contractURI,
        string tokenURIPrefix,
        uint256 time
    );

    event CollectionRemoved(address indexed creator, address indexed collection, uint256 time);

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
    }

    /**
     * @dev Public function that deploys new collection contract and return new collection address.
     * @dev Returns address of deployed contract
     * @param name Display name for  collection contract
     * @param symbol Symbol for collection contract
     */
    function createCollection(
        string memory name,
        string memory symbol,
        string memory _contractURI,
        string memory tokenURIPrefix
    ) public returns (address) {
        CollectionV2 collection = new CollectionV2(name, symbol, _contractURI, tokenURIPrefix, msg.sender);
        uint256 id = _proxyIdCounter.current();
        _proxyIdCounter.increment();
        _collections[id] = (address(collection));
        _userCollections[msg.sender].push(id);
        emit CollectionCreated(
            msg.sender,
            address(collection),
            name,
            symbol,
            _contractURI,
            tokenURIPrefix,
            block.timestamp
        );
        return address(collection);
    }

    /**
     * @dev Public function that Removes contract address from user's collections.
     */
    function removeCollection(uint256 id) public {
        // Check conditions
        address collection = _collections[id];
        require(collection != address(0), "Collection doesn't exists");
        require(_userCollections[msg.sender][id] > 0, "Collection doesn't exists");
        OwnableUpgradeable _collection = OwnableUpgradeable(collection);
        require(_collection.owner() == address(0), "renounceOwnership of contract required");

        // Delete the address
        delete _userCollections[msg.sender][id];
        _collections[id] = address(0);

        // Trigger the event
        emit CollectionRemoved(msg.sender, collection, block.timestamp);
    }
}