//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libs/LibToken.sol";
import "../utils/ProxyRegistry.sol";

contract ERC721Tradeable is ERC721, Pausable, Ownable {
    using LibToken for uint256;
    using Address for address;
    using Strings for uint256;

    bool private _appendJson;
    string private _collectionName;
    address public _proxyRegistryAddress;
    string public _globalURI;
    uint256 private _version = 1;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURI;
    mapping(uint256 => address) internal _creatorOverride;

    mapping(uint256 => mapping(address => bool)) public _whitelistMinter;

    // "NftCiti721Tradeable", "NFTC721"
    constructor(
        string memory collectionName,
        string memory symbol,
        string memory baseURI,
        address proxyRegistryAddress
    ) ERC721(collectionName, symbol) {
        if (bytes(collectionName).length > 0) {
            setName(collectionName);
        }
        if (bytes(baseURI).length > 0) {
            setBaseURI(baseURI);
        }
        _proxyRegistryAddress = proxyRegistryAddress;
        _appendJson = true;
    }

    modifier onlyOwnerOrProxy() {
        require(
            _isOwnerOrProxy(_msgSender()),
            "ERC721Tradable#onlyOwner: CALLER_IS_NOT_OWNER"
        );
        _;
    }

    function _isOwnerOrProxy(address proxyAddress)
        internal
        view
        returns (bool)
    {
        return owner() == proxyAddress || _isProxyForUser(proxyAddress);
    }

    modifier onlyOwnerOrWhitelist() {
        require(
            _isOwnerOrWhitelist(_msgSender()),
            "ERC721Tradable#onlyOwner: CALLER_IS_NOT_OWNER_OR_WHITELIST"
        );
        _;
    }

    function _isOwnerOrWhitelist(address callerAddress)
        internal
        view
        returns (bool)
    {
        return
            owner() == callerAddress ||
            _whitelistMinter[_version][callerAddress];
    }

    function _isProxyForUser(address proxyAddress)
        internal
        view
        virtual
        returns (bool)
    {
        if (!_proxyRegistryAddress.isContract()) {
            return false;
        }
        ProxyRegistry proxy = ProxyRegistry(_proxyRegistryAddress);
        return proxy.proxies(proxyAddress);
    }

    function setProxyRegistryAddress(address proxyAddress) public onlyOwner {
        _proxyRegistryAddress = proxyAddress;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _globalURI = uri;
    }

    function setName(string memory collectionName) public onlyOwner {
        _collectionName = collectionName;
    }

    function setMetadataFormat(bool appendJson) public onlyOwner {
        _appendJson = appendJson;
    }

    function _baseURI() internal view override returns (string memory) {
        return _globalURI;
    }

    function name() public view virtual override returns (string memory) {
        return _collectionName;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function creator(uint256 tokenId) public view returns (address) {
        if (_creatorOverride[tokenId] != address(0)) {
            return _creatorOverride[tokenId];
        } else {
            return tokenId.tokenCreator();
        }
    }

    function checkIfTokenExist(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function whitelistMint(address to, uint256 tokenId)
        external
        onlyOwnerOrWhitelist
    {
        _mint(to, tokenId);
        _creatorOverride[tokenId] = to;
    }

    function mint(address to, uint256 tokenId) external onlyOwnerOrProxy {
        _mint(to, tokenId);
        _creatorOverride[tokenId] = to;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (_exists(tokenId)) return super.ownerOf(tokenId);
        else return creator(tokenId);
    }

    function setWhitelistMinter(address[] memory minters, bool reset)
        external
        onlyOwner
    {
        if (reset) _version += 1;
        for (uint256 i = 0; i < minters.length; i++) {
            _whitelistMinter[_version][minters[i]] = true;
        }
    }

    function clearWhitelists() external onlyOwner {
        _version += 1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) return "";

        return
            _appendJson
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}