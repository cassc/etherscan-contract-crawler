// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Extension/ContextMixin.sol";
import "./Extension/ERC721URIStorage.sol";
import "./Extension/ERC721Royalty.sol";
import "./IERC721Impl.sol";
import "./ERC721Factory.sol";
import '../Access/AccessMinter.sol';


contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract
 * use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Impl is Ownable, AccessMinter, ContextMixin, ERC721URIStorage, ERC721Royalty, IERC721Impl {
    using Counters for Counters.Counter;

    // Token parameters
    uint256 public maxSupply;
    Counters.Counter internal mintedCounter;
    Counters.Counter internal burnedCounter;

    // Approved
    address public proxyRegistryAddress;

    // Uri
    string public baseUri;

    // Reserved URIs
    string[] public reservedURIs;
    uint256 public reservedURICounter;

    // Modifiers
    modifier onlyWhenMintable(uint256 amount) {
        require(canMint(amount), 'ERC721: cannot mint that amount of tokens');
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, address proxyRegistryAddress_)
    ERC721(name_, symbol_)
    {
        maxSupply = maxSupply_; // 0 = Inf
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        mintedCounter.increment();
        burnedCounter.increment();
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    function owner() public view override(IERC721Impl, Ownable) returns (address) {
        return super.owner();
    }

    // Core functions
    function mintTo(address to) public override {
        mintTo(to, 1, new string[](0));
    }

    function mintTo(address to, string memory uri) public override {
        string[] memory uriList = new string[](1);
        uriList[0] = uri;
        mintTo(to, 1, uriList); // onlyOwner check is performed in this call instead
    }

    function mintTo(address to, uint256 amount) public override {
        mintTo(to, amount, new string[](0));
    }

    function mintTo(address to, uint256 amount, string[] memory uris) public override onlyMinter onlyWhenMintable(amount) {
        for (uint i=0; i<amount; i++) {
            if (i < uris.length) reservedURIs.push(uris[i]);
            _safeMint(to, mintedCounter.current());
        }
    }

    function canMint(uint256 amount) public virtual view override returns (bool) {
        return (mintedCounter.current() + amount - 1 <= maxSupply || maxSupply == 0);
    }

    function burn(uint256 tokenId) public override {
        require(_msgSender() == ownerOf(tokenId), 'ERC721: to burn token you need to be its owner!');
        _burn(tokenId);
    }

    function _mint(address to, uint256 tokenId) internal override {
        // reservedURIs set to 0 means DNA mechanism is not used so should not be enforced
        // reservedURIs higher than 0 means DNA mechanism is active and should be required for each token to have custom
        // DNA
        require(reservedURIs.length == 0 || reservedURIs.length >= mintedCounter.current(), 'ERC721: token URI missing');

        mintedCounter.increment();
        super._mint(to, tokenId);

        // if token reserved URI exists we should set it
        if (reservedURIs.length > 0 && reservedURICounter < reservedURIs.length) {
            super._setTokenURI(tokenId, reservedURIs[reservedURICounter++]);
        }
    }

    function _burn(uint256 tokenId) internal override {
        burnedCounter.increment();
        super._burn(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        // make sure unintialized tokens are not transferable, so people HAVE to initialize them before putting
        // on opensea
        require(reservedURIs.length == 0 || keccak256(bytes(tokenURIs[tokenId])) != keccak256(bytes("")),
            'ERC721: cannot transfer token before dna initialization');
        super._transfer(from, to, tokenId);
    }

    // Uri functions
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public override onlyMinter {
        super._setTokenURI(tokenId, _tokenURI);
        emit TokenUriSet(tokenId, _tokenURI);
    }

    function getTokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId];
    }

    function setBaseURI(string memory _uri) public override onlyMinterOrOwner {
        baseUri = _uri;
        emit BaseUriSet(_uri);
    }

    // Additional functions
    function totalSupply() external view returns (uint256) {
        return mintedCounter.current() - burnedCounter.current();
    }

    function totalMinted() external view override returns (uint256) {
        return mintedCounter.current() - 1;
    }

    function totalBurned() external view override returns (uint256) {
        return burnedCounter.current() - 1;
    }

    // Royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external override onlyMinterOrOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external override onlyMinterOrOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external override onlyMinterOrOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external override onlyMinterOrOwner {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator) public override(ERC721, IERC721) view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }
        
        // Whitelist minting owner for easier integration
        if (isMinter(_operator)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981, IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Impl).interfaceId || super.supportsInterface(interfaceId);
    }
}