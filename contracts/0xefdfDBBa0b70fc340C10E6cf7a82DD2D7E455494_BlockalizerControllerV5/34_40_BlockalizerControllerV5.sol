// contracts/BlockalizerV4.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IBlockalizer.sol";
import "./BlockalizerV3.sol";
import "./BlockalizerGenerationV2.sol";

// uncomment this line when debugging
// import "hardhat/console.sol";

contract BlockalizerControllerV5 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using ECDSA for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _collectionIdCounter;
    mapping(uint256 => address) private _collections;
    event Collection(uint256 indexed _id, address indexed _address);

    CountersUpgradeable.Counter private _generationCounter;
    mapping(uint256 => address) private _generations;
    event Generation(uint256 indexed _id, address indexed _address);

    mapping(address => bool) private _whitelisted;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    error MaxMinted(uint256 maximum);
    error UserMaxMinted(uint256 maximum);
    error PaymentDeficit(uint256 value, uint256 price);
    error MintNotAllowed(address sender);
    error MintNotLive();
    error InvalidGeneration();

    bytes32 public merkleRoot;

    bytes32 public constant AUTHORIZER_ROLE = keccak256("AUTHORIZER_ROLE");

    mapping(bytes32 => bool) private _seen;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint96 _mintPrice,
        uint96 _maxSupply,
        uint32 _expiryTime,
        uint32 _startTime,
        uint32 _maxMintsPerWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        address sender = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);

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

    function _initializeGeneration(
        uint96 _mintPrice,
        uint96 _maxSupply,
        uint32 _expiryTime,
        uint32 _startTime,
        uint32 _maxMintsPerWallet
    ) internal {
        if (_expiryTime <= block.timestamp) {
            revert InvalidGeneration();
        }
        uint256 generationId = _generationCounter.current();
        BlockalizerGenerationV2 generation = new BlockalizerGenerationV2(
            _mintPrice,
            _maxSupply,
            _expiryTime,
            _startTime,
            uint16(_maxMintsPerWallet)
        );
        _generations[generationId] = address(generation);

        emit Generation(generationId, _generations[generationId]);
    }

    function getCollection(
        uint256 _collectionId
    ) external view returns (address) {
        return _collections[_collectionId];
    }

    function getGenerationCount() public view returns (uint256) {
        return _generationCounter.current();
    }

    function getGeneration() public view returns (address) {
        uint256 generationId = _generationCounter.current();
        return _generations[generationId];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function startGeneration(
        uint96 _mintPrice,
        uint96 _maxSupply,
        uint32 _expiryTime,
        uint32 _startTime,
        uint32 _maxMintsPerWallet
    ) external onlyRole(AUTHORIZER_ROLE) {
        _generationCounter.increment();
        _initializeGeneration(
            _mintPrice,
            _maxSupply,
            _expiryTime,
            _startTime,
            uint16(_maxMintsPerWallet)
        );
    }

    function withdrawAll() public onlyRole(UPGRADER_ROLE) {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }

    function setTokenURI(
        uint256 _collectionId,
        uint256 _tokenId,
        string memory _uri
    ) public onlyRole(AUTHORIZER_ROLE) {
        IBlockalizer collection = IBlockalizer(_collections[_collectionId]);
        collection.setTokenURI(_tokenId, _uri);
    }

    function setMerkleRoot(
        bytes32 merkleRoot_
    ) external onlyRole(AUTHORIZER_ROLE) {
        merkleRoot = merkleRoot_;
    }

    function preMint(
        bytes memory _uri,
        bytes memory sig,
        bytes32[] calldata merkleProof
    ) public payable {
        uint256 _collectionId = _collectionIdCounter.current();
        IBlockalizer collection = IBlockalizer(_collections[_collectionId]);
        uint256 tokenId = collection.currentTokenId();
        uint256 generationId = _generationCounter.current();
        BlockalizerGenerationV2 generation = BlockalizerGenerationV2(
            _generations[generationId]
        );

        if (
            !isOnWhitelist(merkleProof) ||
            block.timestamp > generation.expiryTime()
        ) {
            revert MintNotLive();
        }

        checkMintRequirements(generationId, _uri, sig);

        collection.safeMint(_msgSender(), tokenId);
        collection.setTokenURI(tokenId, string(_uri));
        generation.incrementTokenCount(_msgSender());
        collection.incrementTokenId();
    }

    function isOnWhitelist(
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        bytes32 account = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, account);
    }

    function publicMint(bytes memory _uri, bytes memory sig) public payable {
        uint256 _collectionId = _collectionIdCounter.current();
        IBlockalizer collection = IBlockalizer(_collections[_collectionId]);
        uint256 tokenId = collection.currentTokenId();
        uint256 generationId = _generationCounter.current();
        BlockalizerGenerationV2 generation = BlockalizerGenerationV2(
            _generations[generationId]
        );

        if (
            block.timestamp < generation.startTime() ||
            block.timestamp > generation.expiryTime()
        ) {
            revert MintNotLive();
        }

        checkMintRequirements(generationId, _uri, sig);

        collection.safeMint(_msgSender(), tokenId);
        collection.setTokenURI(tokenId, string(_uri));
        collection.incrementTokenId();
        generation.incrementTokenCount(_msgSender());
    }

    function checkMintRequirements(
        uint256 _generationId,
        bytes memory _uri,
        bytes memory sig
    ) internal {
        BlockalizerGenerationV2 _generation = BlockalizerGenerationV2(
            _generations[_generationId]
        );
        if (msg.value != _generation.mintPrice()) {
            revert PaymentDeficit(msg.value, _generation.mintPrice());
        }

        uint256 tokenCount = _generation.getTokenCount();
        if (_generation.maxSupply() <= tokenCount) {
            revert MaxMinted(_generation.maxSupply());
        }

        (bytes32 hashed, address recovered) = recoverAddress(
            keccak256(abi.encodePacked(_uri)),
            sig
        );
        if (!hasRole(AUTHORIZER_ROLE, recovered)) {
            revert MintNotAllowed(_msgSender());
        }

        if (seenBefore(hashed)) {
            // if consumed mapping was already set to true
            revert MintNotAllowed(_msgSender());
        }

        if (
            _generation.balanceOf(_msgSender()) >=
            _generation.maxMintsPerWallet()
        ) {
            revert UserMaxMinted(_generation.maxMintsPerWallet());
        }
    }

    function recoverAddress(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bytes32, address) {
        bytes32 hashed = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return (hashed, hashed.recover(signature));
    }

    function seenBefore(bytes32 hashed) internal returns (bool) {
        bool previouslySeen = _seen[hashed];
        _seen[hashed] = true;
        return previouslySeen;
    }
}