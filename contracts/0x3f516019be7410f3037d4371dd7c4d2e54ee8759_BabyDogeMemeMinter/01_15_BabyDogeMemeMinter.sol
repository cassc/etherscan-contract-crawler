// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMintable.sol";
import "./SafeOwnable.sol";

// @title ERC721 contract
// TokenURI is generated as `{baseURI}{tokenId}.json` or {individualURI} (if base URI is empty)
contract BabyDogeMemeMinter is IERC165, ERC721, SafeOwnable, IMintable, IERC2981 {
    using Strings for uint256;

    string public baseURI;
    address public royaltyReceiver;
    uint16 public royaltyShare;

    uint256 public totalSupply;
    address public mintManager;
    address public metadataManager;

    mapping(uint256 => string) private individualURIs;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event BaseUriUpdated(string);
    event MintManagerUpdated(address);
    event RoyaltyInfoUpdated(address royaltyReceiver, uint16 royaltyShare);
    event MetadataManagerUpdated(address);

    // @notice Allows execution only for owner oe metadata manager
    modifier onlyOwnerOrMetadataManager {
        require(msg.sender == owner() || msg.sender == metadataManager, "Not an owner or metadata manager");
        _;
    }


    /*
     * @param name NFT Name
     * @param symbol NFT Symbol
     * @param _mintManager MintManager address
     * @param _royaltyReceiver Royalty receiver address
     * @param _royaltyShare Royalty share in basis points. Example: 1000 - 10%
     */
    constructor(
        string memory name,
        string memory symbol,
        address _mintManager,
        address _royaltyReceiver,
        uint16 _royaltyShare
    ) ERC721(name, symbol) {
        baseURI = "";
        require(address(0) != _mintManager, "invalid MintManager");
        mintManager = _mintManager;

        require(_royaltyShare <= 1000, "royaltyShare > 10%");
        require(_royaltyReceiver != address(0), "Invalid royaltyReceiver");
        royaltyReceiver = _royaltyReceiver;
        royaltyShare = _royaltyShare;
    }


    /*
     * @notice Mints token with approved individualURI and tokenId
     * @param receiver Future token owner
     * @param tokenId Token ID index
     * @param individualURI Individual token URI for the token
     */
    function mint (
        address receiver,
        uint256 tokenId,
        string calldata individualURI
    ) external {
        require(msg.sender == mintManager, "Not MintManager");

        individualURIs[tokenId] = individualURI;
        totalSupply++;

        _mint(receiver, tokenId);
    }


    /*
     * @notice Burns token with specific ID by the owner
     */
    function burn(uint256 _tokenId) external {
        require(msg.sender == _ownerOf(_tokenId), "must be owner");

        totalSupply--;

        _burn(_tokenId);
    }


    /*
     * @notice Emit update event for individual token Metadata
     * @param _tokenId Token ID index
     * @dev Should be called in case of metadata update. Can be called only by the Owner or MetadataManager
     */
    function updateMetadata(uint256 _tokenId) external onlyOwnerOrMetadataManager {
        require(_exists(_tokenId), "invalid tokenId");
        emit MetadataUpdate(_tokenId);
    }


    /*
     * @notice Emit  batch update event for the list of individual tokens Metadata
     * @param fromTokenId Starting index of tokens with updated metadata
     * @param toTokenId Ending index of tokens with updated metadata
     * @dev Should be called in case of metadata update. Can be called only by the Owner or MetadataManager
     */
    function batchUpdateMetadata(uint256 fromTokenId, uint256 toTokenId) external onlyOwnerOrMetadataManager {
        require(fromTokenId <= toTokenId, "invalid range");
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }


    /*
     * @notice Emit update event for the list of individual tokens Metadata
     * @param tokenIds Array of token IDs
     * @dev Should be called in case of metadata update. Can be called only by the Owner or MetadataManager
     */
    function updateMetadataForTokens(uint256[] memory tokenIds) external onlyOwnerOrMetadataManager {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit MetadataUpdate(tokenIds[i]);
        }
    }


    /*
     * @notice Updates baseURI string
     * @param baseURI_ New base URI string
     * @dev Can be called only by the Owner
     */
    function setBaseUri(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseUriUpdated(baseURI_);
    }


    /*
     * @notice Updates MintManager address
     * @param _mintManager MintManager contract address, which will exclusively allowed to mint
     * @dev Can be called only by the Owner
     */
    function setMintManager(address _mintManager) external onlyOwner {
        require(address(0) != _mintManager, "invalid MintManager");
        require(mintManager != _mintManager, "Already set");
        mintManager = _mintManager;
        emit MintManagerUpdated(_mintManager);
    }


    /*
     * @notice Updates metadata manager address
     * @param _metadataManager Metadata manager address, which will allowed to update metadata
     * @dev Can be called only by the Owner
     */
    function setMetadataManager(address _metadataManager) external onlyOwner {
        require(metadataManager != _metadataManager, "Already set");
        metadataManager = _metadataManager;
        emit MetadataManagerUpdated(_metadataManager);
    }


    /*
     * @notice Updates individual token URIs
     * @param tokenIds Array of token IDs to change URIs for
     * @param individualTokenURIs Array of corresponding token URIs
     * @dev Can be called only by the Owner or metadataManager
     */
    function setIndividualTokenURIs(
        uint256[] calldata tokenIds,
        string[] calldata individualTokenURIs
    ) external onlyOwnerOrMetadataManager {
        require(tokenIds.length == individualTokenURIs.length, "Invalid array length");
        for (uint i = 0; i < tokenIds.length; i++) {
            individualURIs[tokenIds[i]] = individualTokenURIs[i];
        }
    }


    /**
     * @notice Returns token URI link
     * @return Token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return individualURIs[_tokenId];
        }

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }


    /*
     * @notice Updates Royalty received and royalty share
     * @param _royaltyReceiver Royalty receiver address
     * @param _royaltyShare Royalty share in basis points. Example: 1000 - 10%
     */
    function setRoyaltySettings(
        address _royaltyReceiver,
        uint16 _royaltyShare
    ) external onlyOwner {
        require(_royaltyShare <= 1000, "royaltyShare > 10%");
        require(_royaltyReceiver != address(0), "Invalid royaltyReceiver");
        royaltyReceiver = _royaltyReceiver;
        royaltyShare = _royaltyShare;

        emit RoyaltyInfoUpdated(_royaltyReceiver, _royaltyShare);
    }


    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom.
     * @ param  _tokenId     The NFT asset queried for royalty information.
     * @param  _salePrice    The sale price of the NFT asset specified by _tokenId.
     *
     * @return receiver      Address of who should be sent the royalty payment.
     * @return royaltyAmount The royalty payment amount for _salePrice.
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * royaltyShare) / 10_000;
        receiver = royaltyReceiver;
    }


    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        // ERC-4906: EIP-721 Metadata Update Extension
        return interfaceId == bytes4(0x49064906)
            || interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }
}