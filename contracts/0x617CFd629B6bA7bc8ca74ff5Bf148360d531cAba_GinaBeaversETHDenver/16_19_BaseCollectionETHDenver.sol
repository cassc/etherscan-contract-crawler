// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

/**
 * @title BaseCollectionETHDenver
 * BaseCollectionETHDenver - a contract for my non-fungible tokens to be sold on ETHDENVER.
 * @author @vtleonardo, @z-j-lin
 */
abstract contract BaseCollectionETHDenver is
    ERC721Enumerable,
    Ownable,
    ERC2981,
    UpdatableOperatorFilterer
{
    // The Operator Filter Registry address
    address public constant OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;
    // The default subscription address
    address public constant DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    // The max supply
    uint256 public immutable maxSupply;
    // The royalty percent
    uint96 public royaltyPercent;
    // The price of each token
    uint256 public pricePerToken;
    // The COAProxy address
    address public coaProxy;
    // The base URI for all tokens
    string public baseURI = "";
    // The artist address (address that will receive the royalties and the eth on the contract)
    address public artist;
    // The minting status
    bool public isMintingEnabled = true;
    // tokenID tracker
    uint32 internal _tokenID;

    modifier onlyIfMintEnabled() {
        require(isMintingEnabled, "minting is disabled");
        _;
    }

    modifier onlyCOAProxy() {
        require(msg.sender == coaProxy, "Only COAProxy can mint");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint96 royaltyPercent_,
        uint256 maxSupply_,
        uint256 pricePerToken_,
        address coaProxy_,
        address artist_
    )
        ERC721(name_, symbol_)
        UpdatableOperatorFilterer(OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true)
    {
        coaProxy = coaProxy_;
        royaltyPercent = royaltyPercent_;
        pricePerToken = pricePerToken_;
        maxSupply = maxSupply_;
        _setArtist(artist_);
    }

    /**
     * @notice Sets the COAProxy address
     * @param coaProxy_ The COAProxy address
     */
    function setCOAProxy(address coaProxy_) external onlyOwner {
        coaProxy = coaProxy_;
    }

    /**
     * @notice Sets the artist address
     * @param artist_ The artist address
     */
    function setArtist(address artist_) external onlyOwner {
        _setArtist(artist_);
    }

    /**
     * @dev Sets the price per token
     * @param pricePerToken_ The price per token
     */
    function setPricePerToken(uint256 pricePerToken_) external onlyOwner {
        pricePerToken = pricePerToken_; // set the price per token
    }

    /**
     * @dev Sets the royalty percent
     * @param royaltyPercent_ The royalty percent
     */
    function setRoyaltyPercent(uint96 royaltyPercent_) external onlyOwner {
        royaltyPercent = royaltyPercent_; // set the royalty percent
        _setDefaultRoyalty(address(artist), royaltyPercent);
    }

    /**
     * @dev Sets the base URI
     * @param baseURI_ The base URI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_; // set the base URI
    }

    /**
     * @notice Withdraws the funds from the contract. Only the owner can call this function. The
     * funds are sent to the artist address.
     */
    function withdraw(address to_) external onlyOwner {
        payable(to_).transfer(address(this).balance);
    }

    /**
     * @notice toggles (enable/disable) the minting status
     */
    function toggleMintingEnabled() external onlyOwner {
        isMintingEnabled = !isMintingEnabled;
    }

    /**
     * @notice Mints a new NFT
     */
    function mint(address to_) public payable virtual onlyIfMintEnabled onlyCOAProxy {
        uint32 tokenID = _tokenID + 1;
        require(tokenID <= maxSupply, "Max supply reached");
        require(msg.value >= pricePerToken, "Insufficient funds");
        _tokenID = tokenID;
        _mint(to_, tokenID);
    }

    /**
     *************************************************************************
     * @notice the following are overrides for the ERC721Enumerable functions
     * required by OperatorFilterer which allows OpenSea to enforce royalties
     *************************************************************************
     */
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

    /**
     *************************************************************************
     */

    /**
     * @dev Returns the token URI
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        // Check if the token exists using the _exists function
        require(_exists(tokenId_), "Token does not exist");
        // Return the base URI
        return baseURI;
    }

    /**
     **************************************************************************
     */
    /**
     * @dev Returns the owner of the contract
     * @notice This is required by the OperatorFilterer contract
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner(); // return the owner
    }

    /**
     * @dev Returns the interface ID of supports interfaces
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId); // return the interface ID
    }

    function totalMinted() public view returns (uint256) {
        return _tokenID; // returns the token id
    }

    function _setArtist(address artist_) internal {
        require(artist_ != address(0), "Artist cannot be 0 address");
        artist = artist_;
        _setDefaultRoyalty(address(artist_), royaltyPercent);
    }
}