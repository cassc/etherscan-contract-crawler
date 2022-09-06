pragma solidity ^0.8.13;

import "Base64.sol";
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
    bytes32 public constant ARWEAVE_DEV_BASE_URI_HASHED = keccak256(bytes("https://voice-arweave.dev.vops.co/"));
    bytes32 public constant ARWEAVE_PROD_BASE_URI_HASHED = keccak256(bytes("https://arweave.net/"));
    string public constant PLUS = "+";
    bytes1 public constant PLUS_BYTES = bytes1(bytes(PLUS));
    string public constant PLUS_REPLACEMENT = "-";
    bytes1 public constant PLUS_REPLACEMENT_BYTES = bytes1(bytes(PLUS_REPLACEMENT));
    string public constant SLASH = "/";
    bytes1 public constant SLASH_BYTES = bytes1(bytes(SLASH));
    string public constant SLASH_REPLACEMENT = "_";
    bytes1 public constant SLASH_REPLACEMENT_BYTES = bytes1(bytes(SLASH_REPLACEMENT));
    string public constant EQUALS = "=";
    bytes1 public constant EQUALS_BYTES = bytes1(bytes("="));

    mapping(uint256 => AssetsData) internal _assets;
    mapping(bytes32 => string) internal _dataStrings;

    CountersUpgradeable.Counter internal _tokenIds;
    CountersUpgradeable.Counter internal _totalBurned;

    function burn(uint256 tokenId) external virtual onlyOwnerOrBridge(tokenId) {
        _burn(tokenId);
        _totalBurned.increment();
    }

    function create(
        address owner,
        string memory category,
        bytes32 jsonMeta,
        string memory baseUri)
    external
    virtual
    onlyRole(BRIDGE)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(owner, newItemId);
        _create(newItemId, owner, category, jsonMeta, baseUri);
    }

    function getAssetsCategory(uint256 tokenId) external view virtual returns (string memory){
        return _dataStrings[_assets[tokenId].category];
    }

    function getAssetsIDataByIndex(
        uint256 tokenId,
        uint256 index
    ) external
    view
    virtual
    returns (string memory key, string memory value)
    {
        bytes32 hashedKey = _assets[tokenId].idataKey[index];
        bytes32 hashedValue = _assets[tokenId].idata[hashedKey];
        key = _dataStrings[hashedKey];
        value = _dataStrings[hashedValue];
    }

    function getAssetsIDataByKey(
        uint256 tokenId,
        string memory key
    ) external
    view
    virtual
    returns (string memory value)
    {
        bytes32 hashedKey = _getSavedHashedKey(key);
        bytes32 hashedValue = _assets[tokenId].idata[hashedKey];
        value = _dataStrings[hashedValue];
    }

    function getAssetsIDataLength(uint256 tokenId) external view returns (uint256){
        return _assets[tokenId].idataKey.length;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, IERC721MetadataUpgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes32 hashedBaseURI = _assets[tokenId].idata[URI_BASE_IDATA_HASHED_KEY];
        string memory baseURI = _dataStrings[hashedBaseURI];
        bytes32 jsonMeta = _getJsonMeta(tokenId);

        if (hashedBaseURI == ARWEAVE_PROD_BASE_URI_HASHED || hashedBaseURI == ARWEAVE_DEV_BASE_URI_HASHED) {
            return string(abi.encodePacked(baseURI, _urlEncode(jsonMeta)));
        }

        return string(abi.encodePacked(baseURI, toHexStringNoPrefix(uint256(jsonMeta))));
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection,
     * @dev and setting a `name` and a `symbol` to the token collection
     */
    function initialize(string memory name_, string memory symbol_) public initializer {
        __UUPSUpgradeable_init();
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
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
        string memory category,
        bytes32 jsonMeta,
        string memory baseUri
    )
    internal
    virtual
    {
        _assets[tokenId].category = _saveString(category);

        KeyValue memory baseUriKeyValue = KeyValue('URI_BASE', baseUri);

        _setIdata(tokenId, baseUriKeyValue);

        require(_idataExists(tokenId, URI_BASE_IDATA_HASHED_KEY), "SimpleAssets: must have URI base in idata");

        _setJsonMeta(tokenId, jsonMeta);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function _setIdata(uint256 tokenId, KeyValue memory idata) internal virtual {
        bytes32 key = _saveString(idata.key);
        require(!_idataExists(tokenId, key), "SimpleAssets: immutable values can only be set once.");
        _assets[tokenId].idataKey.push(key);
        _assets[tokenId].idata[key] = _saveString(idata.value);
        emit ImmutableValueAssigned(msg.sender, tokenId, idata.key, idata.value);
    }

    function _setJsonMeta(uint256 tokenId, bytes32 jsonMeta) internal virtual {
        _assets[tokenId].idata[JSON_META_IDATA_HASHED_KEY] = jsonMeta;
        emit ImmutableValueAssigned(msg.sender, tokenId, JSON_META_IDATA_KEY, toHexStringNoPrefix(uint256(jsonMeta)));
    }

    function _saveString(string memory s) internal virtual returns (bytes32){
        bytes32 key = _toKey(s);
        if (bytes(_dataStrings[key]).length == 0) {
            _dataStrings[key] = s;
        }
        return key;
    }

    function _urlEncode(bytes32 meta) internal virtual view returns (string memory) {
        string memory encoded = Base64.encode(abi.encodePacked(meta));
        bytes memory stringBytes = bytes(encoded);
        uint strippedLength = 0;

        for (uint i = 0; i < stringBytes.length; i++) {
            if (stringBytes[i] != EQUALS_BYTES) {
                strippedLength++;
            }
        }

        bytes memory result = new bytes(strippedLength);

        for (uint i = 0; i < stringBytes.length; i++) {
            if (stringBytes[i] == PLUS_BYTES) {
                result[i] = PLUS_REPLACEMENT_BYTES;
            } else if (stringBytes[i] == SLASH_BYTES) {
                result[i] = SLASH_REPLACEMENT_BYTES;
            } else if (stringBytes[i] != EQUALS_BYTES) {
                result[i] = stringBytes[i];
            }
        }
        return string(result);
    }

    function _getJsonMeta(uint256 tokenId) internal virtual view returns (bytes32 jsonMeta){
        jsonMeta = _assets[tokenId].idata[JSON_META_IDATA_HASHED_KEY];
    }

    function _getSavedHashedKey(string memory s) internal virtual view returns (bytes32){
        bytes32 key = _toKey(s);
        require(bytes(_dataStrings[key]).length > 0, "SimpleAssets: the key must exist");
        return key;
    }

    function _idataExists(uint256 tokenId, bytes32 key) internal view virtual returns (bool) {
        return _assets[tokenId].idata[key] > 0;
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