// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../erc721/ERC721Base.sol";

/**
 * @title Gooodfellas Non-Fungo Pops Contract
 */
contract GooodfellasNonFungoPops is ERC721Base, ReentrancyGuard {
    using Strings for uint256;
    using Address for address payable;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public immutable gooodToken;

    // baseURI to override all tokenIds
    string private baseURI;

    // doubles as guard
    mapping(address => string) private collectionUnrevealedURIs;
    mapping(uint256 => string) private revealedURIs;

    // tokenId => itemId
    mapping(uint256 => uint256) private itemIds;

    // itemId => tokenId
    mapping(uint256 => uint256) private tokenIds;

    mapping(address => bool) public isRevealer;

    address payable public paymentReceiver;
    uint256 public priceGOOOD = 1_500_000 ether;
    uint256 public priceBNB = 0;
    bool public mintActive = false;


    constructor(
        address payable _paymentReceiver,
        address _gooodToken
    )
        ERC721("Gooodfellas Non-Fungo Pops", "OOO-NFP")
    {
        require(_paymentReceiver != address(0), "Payment receiver not set");
        paymentReceiver = _paymentReceiver;
        gooodToken = _gooodToken;
    }


    /**
     * @notice Mint non-Fungo Pop for `_tokenId` of `_collection` paying with GOOOD tokens.
     */
    function mintWithGOOOD(address _collection, uint256 _tokenId) external nonReentrant {
        require(mintActive, "Mint not active");
        require(priceGOOOD != 0, "Mint with GOOOD not acive");
        require(IERC721(_collection).ownerOf(_tokenId) == msg.sender, "Needs to own base NFT");
        IERC20(gooodToken).transferFrom(msg.sender, BURN_ADDRESS, priceGOOOD);

        _mintInternal(msg.sender, _collection, _tokenId);
    }

    /**
     * @notice Mint non-Fungo Pop for `_tokenId` of `_collection` paying with GOOOD tokens.
     */
    function mintWithBNB(address _collection, uint256 _tokenId) external payable nonReentrant {
        require(mintActive, "Mint not active");
        require(priceBNB != 0, "Mint with BNB not acive");
        require(msg.value == priceBNB, "Invalid BNB amount");
        require(IERC721(_collection).ownerOf(_tokenId) == msg.sender, "Needs to own base NFT");
        
        paymentReceiver.sendValue(msg.value);

        _mintInternal(msg.sender, _collection, _tokenId);
    }

    /**
     * @notice Mint non-Fungo Pop for `_tokenId` of `_collection` as owner for giveaway or future extension.
     */
    function mint(address _recipient, address _collection, uint256 _tokenId) external onlyOwner nonReentrant {
        _mintInternal(_recipient, _collection, _tokenId);
    }

    /**
     * @notice Reveal metadata of non-Fungo Pop
     */
    function reveal(uint256 _nfpTokenId, address _collection, uint256 _collectionTokenId, string calldata _uri) external {
        require(isRevealer[msg.sender], "Only revealer");
        require(_getTokenId(_collection, _collectionTokenId) == _nfpTokenId, "Data validation failed");

        revealedURIs[_nfpTokenId] = _uri;
    }

    /**
     * @notice Reveal batch of metadata of non-Fungo Pop, no verification!
     */
    function batchReveal(uint256[] calldata _tokenIds, string[] calldata _uris) external {
        require(isRevealer[msg.sender], "Only revealer");
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            require(_exists(_tokenIds[i]), "TokenId does not exist");
            revealedURIs[_tokenIds[i]] = _uris[i];
        }
    }

    /**
     * @notice Set the URI for a unrevealed item of a collection. 
     * Marks this collection availavle for minting.
     * Set to empty string to disable minting for that collection. 
     */
    function setCollectionUnrevealedURIs(address _collection, string calldata _uri) external onlyOwner {
        collectionUnrevealedURIs[_collection] = _uri;
    }

    /**
     * @notice Mark address to be allowed to call reveal method.
     */
    function setIsRevealer(address _user, bool _isRevealer) external onlyOwner {
        isRevealer[_user] = _isRevealer;
    }

    /**
     * @notice Forward BNB which ended up in this contract by accident to paymentReceiver. Only owner.
     */
    function forwardFunds() external onlyOwner nonReentrant {
        uint256 available = address(this).balance;
        require(available > 0, "Nothing to withdraw");
        paymentReceiver.sendValue(available);
    }

    /**
     * @notice Change priceGOOOD to `_priceGOOOD` in WEI.
     */
    function setPriceGoood(uint256 _priceGOOOD) external onlyOwner {
        priceGOOOD = _priceGOOOD;
    }

    /**
     * @notice Change priceGOOOD to `_priceGOOOD` in WEI.
     */
    function setPriceBNB(uint256 _priceBNB) external onlyOwner {
        priceBNB = _priceBNB;
    }

    /**
     * @notice Set mintActive to `_mintActive`. Only callable by owner.
     */
    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    /**
     * @notice Set payment receiver to `_paymentReceiver`. Only callable by owner.
     */
    function setPaymentReceiver(address payable _paymentReceiver) external onlyOwner {
        require(_paymentReceiver != address(0), "Invalid payment receiver not set");
        paymentReceiver = _paymentReceiver;
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all not revealed token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (bytes(baseURI).length > 0) return string(abi.encodePacked(baseURI, _tokenId.toString()));
        if (bytes(revealedURIs[_tokenId]).length > 0) return revealedURIs[_tokenId];

        (address collection, ) = _getItem(_tokenId); 
        return collectionUnrevealedURIs[collection];
    }

    function baseNFT(uint256 _tokenId) external view returns (address collection, uint256 tokenId) {
        require(_exists(_tokenId), "NFP does not exist");
        return _getItem(_tokenId);
    }

    /** @dev return of 0 means no NFP exists for that combination */
    function tokenIdOf(address _collection, uint256 _tokenId) external view returns (uint256 tokenId) {
        return _getTokenId(_collection, _tokenId);
    }

    function _mintInternal(address _recipient, address _collection, uint256 _tokenId) internal {
        uint256 itemId = _encodeItem(_collection, _tokenId);
        uint256 tokenId = totalSupply() + 1;

        require(bytes(collectionUnrevealedURIs[_collection]).length > 0, "Unknown collection");
        require(tokenIds[itemId] == 0, "NFP already exists");
        
        tokenIds[itemId] = tokenId;
        itemIds[tokenId] = itemId;

        _safeMint(_recipient, tokenId);
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _getItem(uint256 _tokenId) internal view returns (address collection, uint256 tokenId) {
        return _decodeItem(itemIds[_tokenId]);
    }

    function _getTokenId(address _collection, uint256 _tokenId) internal view returns (uint256) {
        return tokenIds[_encodeItem(_collection, _tokenId)];
    }

    function _encodeItem(address _collection, uint256 _tokenId) internal pure returns (uint256) {
        return uint256(uint160(_collection)) | (_tokenId << 160); 
    }

    function _decodeItem(uint256 _collectionAndTokenId) internal pure returns (address collection, uint256 tokenId) {
        collection = address(uint160(_collectionAndTokenId));
        tokenId = (_collectionAndTokenId >> 160);
    }
}