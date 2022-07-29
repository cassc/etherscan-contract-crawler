pragma solidity ^0.8.13;

import "UUPSUpgradeable.sol";
import "AccessControlUpgradeable.sol";
import "CountersUpgradeable.sol";
import "ERC721Upgradeable.sol";
import "ISimpleAssets.sol";


/**
    @title SimpleAsssets port following Voice internal data structure
    @notice inherits common ERC721 functionality from ERC721Upgradeable by OZ
    @notice minting performed exclusively by VoiceAPI while exporting NFTs to Polygon
    @author Oleksii Nahorniak [email protected]
  */
contract SimpleAssets is ISimpleAssets, AccessControlUpgradeable, ERC721Upgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant BRIDGE = keccak256("BRIDGE");
    string public constant URI_BASE_IDATA_KEY = "URI_BASE";
    bytes32 public constant URI_BASE_IDATA_HASHED_KEY = keccak256(bytes(URI_BASE_IDATA_KEY));
    string public constant JSON_META_IDATA_KEY = "JSON_META";
    bytes32 public constant JSON_META_IDATA_HASHED_KEY = keccak256(bytes(JSON_META_IDATA_KEY));
    bytes16 public constant _HEX_SYMBOLS = "0123456789abcdef";

    mapping(uint256 => AssetsData) internal _assets;
    mapping(bytes32 => string) internal _dataStrings;

    CountersUpgradeable.Counter internal _tokenIds;
    CountersUpgradeable.Counter internal _totalBurned;
    string internal _baseUri;

    function burn(uint256 tokenId) external virtual onlyOwnerOrBridge(tokenId) {
        _burn(tokenId);
        _totalBurned.increment();
    }

    function create(
        address owner,
        string memory jsonMeta)
    external
    virtual
    onlyRole(BRIDGE)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(owner, newItemId);
        _create(newItemId, owner, jsonMeta);
    }

    function setBaseUri(string memory baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUri = baseUri;
    }

    function getBaseUri() external view virtual returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, IERC721MetadataUpgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _getBaseUri(tokenId);
        string memory jsonMeta = _getJsonMeta(tokenId);

        return string(abi.encodePacked(baseURI, jsonMeta));
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection,
     * @dev and setting a `name` and a `symbol` to the token collection
     */
    function initialize(string memory name_, string memory symbol_, string memory baseUri_) public initializer {
        __UUPSUpgradeable_init();
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseUri = baseUri_;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override(ERC721Upgradeable, IERC721MetadataUpgradeable) returns (string memory) {
        return "Voice Shared Storefront";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override(ERC721Upgradeable, IERC721MetadataUpgradeable) returns (string memory) {
        return "VOICE";
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlUpgradeable, ERC721Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIds.current() - _totalBurned.current();
    }

    function latestExportedTokenId() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    function _create(
        uint256 tokenId,
        address owner,
        string memory jsonMeta
    )
    internal
    virtual
    {
        _assets[tokenId].jsonMeta = _saveString(jsonMeta);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function _saveString(string memory s) internal virtual returns (bytes32){
        bytes32 key = _toKey(s);
        if (bytes(_dataStrings[key]).length == 0) {
            _dataStrings[key] = s;
        }
        return key;
    }

    function _getBaseUri(uint256 tokenId) internal virtual view returns (string memory) {
        bytes32 hashedBaseUri = _assets[tokenId].idata[URI_BASE_IDATA_HASHED_KEY];
        
        if (hashedBaseUri > 0) {
            return _dataStrings[hashedBaseUri];
        }

        return _baseUri;
    }

    function _getJsonMeta(uint256 tokenId) internal virtual view returns (string memory){
        bytes32 jsonMeta = _assets[tokenId].idata[JSON_META_IDATA_HASHED_KEY];

        if (jsonMeta > 0) {
            return toHexStringNoPrefix(uint256(jsonMeta));
        }

        bytes32 jsonMetaKey = _assets[tokenId].jsonMeta;
        return _dataStrings[jsonMetaKey];
    }

    function _toKey(string memory s) internal pure virtual returns (bytes32) {
        return keccak256(bytes(s));
    }

    function toHexStringNoPrefix(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 64; i > 0; --i) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    modifier onlyOwnerOrBridge(uint256 tokenId){
        require(
            hasRole(BRIDGE, msg.sender) || msg.sender == ownerOf(tokenId),
            "SimpleAssets: only token owner of bridge contract can do this"
        );
        _;
    }
}