// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../interfaces/IRiverBox.sol";

interface IRiverMen is IRiverBox, IERC721Upgradeable {}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract RivermenScrollsData {
    struct Hierarchy {
        uint16 parentLocationId;
        uint16[] childLocationIds;
    }

    struct Product {
        uint16 locationId; // the location of product in the stock array
        uint256[] parts; // a list of token ids which are used to fuse this item
    }

    mapping(uint256 => Product) internal _tokenIdDetailMapping;
    mapping(bool => mapping(uint256 => uint256)) internal _tokenIdFusionCountMapping; // tokenID => fusion count
    mapping(uint256 => Hierarchy) internal _tokenHierarchyMapping;
}

contract RivermenScrollsImplV2 is
RivermenScrollsData,
Initializable,
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
PausableUpgradeable,
AccessControlUpgradeable,
ReentrancyGuardUpgradeable,
OwnableUpgradeable,
UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    IRiverMen public rivermen;
    address public proxyRegistryAddress;
    string public baseURI;


    function initialize(
        address _rivermenAddress,
        string memory _initBaseURI,
        address _proxyRegistryAddress
    ) public initializer {
        __ERC721_init("RivermenScrolls", "RS");
        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        rivermen = IRiverMen(_rivermenAddress);
        baseURI = _initBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        _pause();
    }

    /* ================ EVENTS ================ */
    event FusedItemAwarded(address indexed payer, uint256 indexed tokenId, uint256 eventTime);
    event ComposeItemAwarded(address indexed payer, uint256 indexed tokenId, uint256 eventTime,uint256[] fromTokenIds);

    /* ================ VIEWS ================ */
    function fusionCount(uint256 tokenId, bool isPawn) external view returns (uint256) {
        return _tokenIdFusionCountMapping[isPawn][tokenId];
    }

    /**
     * @dev Get token detail information
     */
    function tokenDetail(uint256 tokenId) public view returns (Product memory) {
        require(_exists(tokenId), "Token not exists");
        return _tokenIdDetailMapping[tokenId];
    }

    function tokenInfo(uint256[] memory tokenIds) public view returns (Product[] memory) {
        Product[] memory info = new Product[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            info[i] =  _tokenIdDetailMapping[tokenIds[i]];
        }
        return info;
    }

    function tokenIdsByOwner(address owner) external view returns (uint256[] memory){
        uint256 num = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](num);
        for (uint256 i = 0; i < num; ++i) {
            tokenIds[i] = tokenOfOwnerByIndex(owner,i);
        }
        return tokenIds;
    }

    /**
     * @dev Get token detail information
     */
    function tokenHierarchy(uint256 locationId) external view returns (Hierarchy memory) {
        return _tokenHierarchyMapping[locationId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

    /**
     * @dev Verify if a list of parts can be used to fuse new product
     * @param tokenIds a list of token Ids used to fuse the item
     * @param fromPawn checks if the item is from Pawn stock
     * @param checkOwner checks if the owner needs to be checked
     */
    function verifyFusion(
        uint256[] memory tokenIds,
        bool fromPawn,
        bool checkOwner
    ) public view returns (bool) {
        if (tokenIds.length == 0) return false;
        uint256 tokenId = tokenIds[0];
        uint16 tokenLocationId = fromPawn ? rivermen.tokenDetail(tokenId).locationId : tokenDetail(tokenId).locationId;
        uint16 parentLocationId = _tokenHierarchyMapping[tokenLocationId].parentLocationId;
        if (parentLocationId == 0) return false;
        if (parentLocationId > 277) return false;
        if (_tokenHierarchyMapping[parentLocationId].childLocationIds.length != tokenIds.length) return false;
        address owner;
        uint256[2] memory bitmap;
        uint256 bucket;
        uint256 mask;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            if (_tokenIdFusionCountMapping[fromPawn][tokenId] > 0) return false;
            tokenLocationId = fromPawn ? rivermen.tokenDetail(tokenId).locationId : tokenDetail(tokenId).locationId;
            if (_tokenHierarchyMapping[tokenLocationId].parentLocationId != parentLocationId) return false;
            owner = fromPawn ? rivermen.ownerOf(tokenId) : ownerOf(tokenId);
            if (checkOwner && owner != _msgSender()) return false;
            bucket = tokenLocationId / 256; // bucket can only be 0 or 1, tokenLocationID < 512
            mask = 1 << (tokenLocationId % 256);
            if ((bitmap[bucket] & mask) != 0) return false; // mark each tokenId as used
            bitmap[bucket] |= mask;
        }
        return true;
    }

    function verifyCompose(
        uint256[] memory tokenIds,
        bool checkOwner
    ) public view returns (bool) {
        if (tokenIds.length == 0) return false;
        uint256 tokenId = tokenIds[0];
        uint16 tokenLocationId = tokenDetail(tokenId).locationId;
        uint16 parentLocationId = _tokenHierarchyMapping[tokenLocationId].parentLocationId;
        if (parentLocationId == 0) return false;
        if (_tokenHierarchyMapping[parentLocationId].childLocationIds.length != tokenIds.length) return false;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            tokenLocationId = tokenDetail(tokenId).locationId;
            if (_tokenHierarchyMapping[tokenLocationId].parentLocationId != parentLocationId) return false;
            if (checkOwner && ownerOf(tokenId) != _msgSender()) return false;
            if(_tokenHierarchyMapping[parentLocationId].childLocationIds[i] != tokenLocationId) return false;
        }
        return true;
    }

    function implementationVersion() external pure returns (string memory) {
        return "2.0.0";
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        //Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    /* ================ TRANSACTIONS ================ */

    /**
     * @dev Fuse a list of items to a next level product
     * @param tokenIds a list of token Ids used to fuse the item
     * @param fromPawn checks if the item is from Pawn stock
     */
    function fuse(uint256[] memory tokenIds, bool fromPawn) external whenNotPaused nonReentrant {
        _notContract();
        require(verifyFusion(tokenIds, fromPawn, true), "not a valid list of tokens");
        uint16 tokenLocationId =
        fromPawn ? rivermen.tokenDetail(tokenIds[0]).locationId : _tokenIdDetailMapping[tokenIds[0]].locationId;
        uint16 parentLocationId = _tokenHierarchyMapping[tokenLocationId].parentLocationId;
        Product memory newItem = Product(parentLocationId, tokenIds);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _tokenIdFusionCountMapping[fromPawn][tokenIds[i]] = _tokenIdFusionCountMapping[fromPawn][tokenIds[i]].add(
                1
            );
        }
        uint256 newId = _awardItem(_msgSender());
        _tokenIdDetailMapping[newId] = newItem;
        emit FusedItemAwarded(_msgSender(), newId, block.timestamp);
    }

    function compose(uint256[] memory tokenIds) external whenNotPaused nonReentrant {
        _notContract();
        require(verifyCompose(tokenIds, true), "not a valid list of tokens");
        uint16 tokenLocationId = _tokenIdDetailMapping[tokenIds[0]].locationId;
        uint16 parentLocationId = _tokenHierarchyMapping[tokenLocationId].parentLocationId;
        Product memory newItem = Product(parentLocationId, tokenIds);
        uint256 newId = _awardItem(_msgSender());
        _tokenIdDetailMapping[newId] = newItem;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _burn(tokenIds[i]);
        }
        emit ComposeItemAwarded(_msgSender(), newId, block.timestamp, tokenIds);
    }

    /* ================ ADMIN ACTIONS ================ */

    function pause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        _pause();
    }

    /**
     * @dev Set a new base URI
     * @param newBaseURI new baseURI address
     */
    function setBaseURI(string memory newBaseURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        baseURI = newBaseURI;
    }

    /**
     * @dev Set Hierarchy information to a specific node with locationId in batch
     * @param locationIds A batch of locationId
     * @param parentLocationIds A batch of parentLocationIds
     * @param listChildLocationIds A batch of childLocationIds
     */
    function setHierarchy(
        uint16[] memory locationIds,
        uint16[] memory parentLocationIds,
        uint16[][] memory listChildLocationIds
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        for (uint256 i = 0; i < locationIds.length; ++i) {
            _tokenHierarchyMapping[locationIds[i]] = Hierarchy(parentLocationIds[i], listChildLocationIds[i]);
        }
    }

    function unpause() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        _unpause();
    }

    /* ================ INTERNAL ACTIONS ================ */
    function _notContract() internal view {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
    }

    /**
     * @dev Mint a new Item
     * @param receiver account address to receive the new item
     */
    function _awardItem(address receiver) private returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();
        _safeMint(receiver, newId);
        return newId;
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, _msgSender()), "require upgrader permission");
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}