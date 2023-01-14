// contracts/BlockalizerV4.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BlockalizerV3.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract BlockalizerControllerV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _collectionIdCounter;
    mapping(uint256 => address) private _collections;
    event Collection(uint256 indexed _id, address indexed _address);

    CountersUpgradeable.Counter private _generationCounter;
    mapping(uint256 => address) private _generations;
    event Generation(uint256 indexed _id, address indexed _address);

    mapping(address => bool) private _whitelisted;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint _mintPrice,
        uint256 _maxSupply,
        uint256 _expiryTime,
        uint256 _startTime,
        uint16 _maxMintsPerWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _initializeCollection();
        _initializeGeneration(
            _mintPrice,
            _maxSupply,
            _expiryTime,
            _startTime,
            _maxMintsPerWallet
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function _initializeCollection() internal {
        uint256 collectionId = _collectionIdCounter.current();
        IBlockalizer collection = new BlockalizerV3();
        _collections[collectionId] = address(collection);

        emit Collection(collectionId, _collections[collectionId]);
    }

    function getCollection(
        uint256 _collectionId
    ) external view returns (address) {
        return _collections[_collectionId];
    }

    function _initializeGeneration(
        uint _mintPrice,
        uint256 _maxSupply,
        uint256 _expiryTime,
        uint256 _startTime,
        uint16 _maxMintsPerWallet
    ) internal {
        require(_expiryTime > block.timestamp, "Expiry time must be in future");
        uint256 generationId = _generationCounter.current();
        BlockalizerGenerationV2 generation = new BlockalizerGenerationV2(
            _mintPrice,
            _maxSupply,
            _expiryTime,
            _startTime,
            _maxMintsPerWallet
        );
        _generations[generationId] = address(generation);

        emit Generation(generationId, _generations[generationId]);
    }

    function getGenerationCount() public view returns (uint256) {
        return _generationCounter.current();
    }

    function getGeneration() public view returns (address) {
        uint256 generationId = _generationCounter.current();
        return _generations[generationId];
    }

    function startGeneration(
        uint _mintPrice,
        uint256 _maxSupply,
        uint256 _expiryTime,
        uint256 _startTime,
        uint16 _maxMintsPerWallet
    ) external onlyRole(UPGRADER_ROLE) {
        _generationCounter.increment();
        _initializeGeneration(
            _mintPrice,
            _maxSupply,
            _expiryTime,
            _startTime,
            _maxMintsPerWallet
        );
    }

    function addToWhitelist(
        address[] calldata users
    ) external onlyRole(UPGRADER_ROLE) {
        for (uint i = 0; i < users.length; i++) {
            _whitelisted[users[i]] = true;
        }
    }

    function isInWhitelist(address user) external view returns (bool) {
        return _whitelisted[user];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function publicMint(
        uint256 _collectionId,
        string memory _uri
    ) public payable {
        IBlockalizer collection = IBlockalizer(_collections[_collectionId]);
        uint256 tokenId = collection.currentTokenId();
        uint256 generationId = _generationCounter.current();
        BlockalizerGenerationV2 generation = BlockalizerGenerationV2(
            _generations[generationId]
        );
        uint256 tokenCount = generation.getTokenCount();
        require(
            generation.balanceOf(_msgSender()) < generation.maxMintsPerWallet(),
            "User has already minted max tokens in this generation"
        );
        require(
            generation.maxSupply() > tokenCount,
            "All NFTs in this generation have been minted"
        );
        require(msg.value == generation.mintPrice(), "Not enough ETH provided");
        // whitelisted users can by-pass
        if (!_whitelisted[msg.sender]) {
            require(
                block.timestamp > generation.startTime(),
                "Minting not yet live"
            );
        }
        require(generation.expiryTime() > block.timestamp, "Expiry has passed");

        collection.safeMint(msg.sender, tokenId);
        collection.setTokenURI(tokenId, _uri);
        generation.incrementTokenCount(msg.sender);
        collection.incrementTokenId();
    }

    function withdraw(uint amount) public onlyRole(UPGRADER_ROLE) {
        require(amount < address(this).balance, "Amount greater than balance");

        address payable _to = payable(msg.sender);
        _to.transfer(amount);
    }

    function withdrawAll() public onlyRole(UPGRADER_ROLE) {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }

    function setTokenURI(
        uint256 _collectionId,
        uint256 _tokenId,
        string memory _uri
    ) public onlyRole(UPGRADER_ROLE) {
        IBlockalizer collection = IBlockalizer(_collections[_collectionId]);
        collection.setTokenURI(_tokenId, _uri);
    }
}