// contracts/BlockalizerV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IBlockalizer is IERC721 {
    function currentTokenId() external returns (uint256 tokenId);

    function incrementTokenId() external;

    function setTokenURI(uint256 tokenId, string memory _uri) external;

    function safeMint(address to, uint256 tokenId) external;
}

contract BlockalizerV3 is
    DefaultOperatorFilterer,
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    IBlockalizer
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Blockalizer:Chroma", "CHROMA") {}

    function currentTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function incrementTokenId() public onlyOwner {
        _tokenIdCounter.increment();
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public onlyOwner {
        super._setTokenURI(tokenId, _uri);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        super._safeMint(to, tokenId);
    }

    // The following functions are overrides required by OpenSea Operator Filter

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return
            interfaceId == type(IBlockalizer).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

contract BlockalizerGenerationV2 is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    uint256 public startTime;
    uint public mintPrice;
    uint256 public maxSupply;
    uint256 public expiryTime;
    uint16 public maxMintsPerWallet;

    constructor(
        uint _mintPrice,
        uint256 _maxSupply,
        uint256 _expiryTime,
        uint256 _startTime,
        uint16 _maxMintsPerWallet
    ) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        expiryTime = _expiryTime;
        startTime = _startTime;
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function getTokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function incrementTokenCount(address owner) public onlyOwner {
        _balances[owner]++;
        _tokenIdCounter.increment();
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }
}

// abstract to BlockalizerManager
// which contains logic for generatiosn and collections
// controller is just permissioning etc

contract BlockalizerController is
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
}