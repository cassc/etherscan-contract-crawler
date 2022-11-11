// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title MIDA Portraits contract
 * @dev This is the implementation of the ERC721 MIDA Portraits Non-Fungible Token.
 */
contract MIDAPortraits is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty, Pausable, AccessControlEnumerable {
    // -- Constants --

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");

    // -- State --

    uint256 private _maxSupply;
    uint256 private _buyPrice;
    string private _baseTokenURI;

    // -- Events --

    event MaxSupplyChanged(uint256 oldMaxSupply, uint256 newMaxSupply);
    event BuyPriceChanged(uint256 oldBuyPrice, uint256 newBuyPrice);
    event BaseURIChanged(string oldBaseURI, string newBaseURI);
    event EtherWithdrawn(address indexed who, uint256 amount);

    // -- Modifiers --

    modifier notReachedMaxSupply() {
        require(totalSupply() < _maxSupply, "All NFTs have been mined.");
        _;
    }

    modifier inRangeToken(uint256 tokenId) {
        require(tokenId >= 0 && tokenId < _maxSupply, "The ID is not within the valid range.");
        _;
    }

    // -- Functions --

    /**
     * @dev MIDA Portraits Contract Constructor.
     */
    constructor(uint256 maxSupply, uint256 buyPrice) ERC721("MIDA Portraits", "MPRS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
        _grantRole(COLLECTOR_ROLE, msg.sender);
        _maxSupply = maxSupply;
        _buyPrice = buyPrice;
    }

    /**
     * @dev Pauses the buy function.
     * NOTE: It does not pause other contract functions
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the buy function.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Getter for the max supply.
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Getter for the buy price.
     */
    function getBuyPrice() public view returns (uint256) {
        return _buyPrice;
    }

    /**
     * @dev Getter for the current balance of the contract.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Set the maximum number of tokens that can be minted.
     * @param newMaxSupply Max number of tokens
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyRole(SETTER_ROLE) {
        require(newMaxSupply > totalSupply(), "Max supply must be greater than the total supply");
        uint256 oldMaxSupply = _maxSupply;
        _maxSupply = newMaxSupply;
        emit MaxSupplyChanged(oldMaxSupply, _maxSupply);
    }

    /**
     * @dev Set the minimum price to buy the token.
     * @param newBuyPrice The price being set
     */
    function setBuyPrice(uint256 newBuyPrice) external onlyRole(SETTER_ROLE) {
        uint256 oldBuyPrice = _buyPrice;
        _buyPrice = newBuyPrice;
        emit BuyPriceChanged(oldBuyPrice, _buyPrice);
    }

    /**
     * @dev Set the base URI for the metadata API.
     * @param newBaseURI The URI being set as base
     */
    function setBaseURI(string memory newBaseURI) external onlyRole(SETTER_ROLE) {
        string memory oldBaseURI = _baseTokenURI;
        _baseTokenURI = newBaseURI;
        emit BaseURIChanged(oldBaseURI, _baseTokenURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set the URI for a specific token.
     * @param tokenId Token to set URI
     * @param newTokenURI The URI being set
     */
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external onlyRole(SETTER_ROLE) {
        _setTokenURI(tokenId, newTokenURI);
    }

    /**
     * @dev Set the default royalty payment information.
     * @param receiver Address that should receive the royalties
     * @param feeNumerator Royalty fee
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SETTER_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Set the royalty payment information for a specific token.
     * NOTE: This will take precedence over the default value
     * @param tokenId Token to which these royalties apply
     * @param receiver Address that should receive the royalties
     * @param feeNumerator Royalty fee
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SETTER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Creates a new token for the caller.
     * @param tokenId ID of the token to be created
     *
     * Requirements:
     * - The caller must have the minter role.
     * - The max supply must not have been reached.
     * - `tokenId` must be greater than or equal to 0 and less than max supply.
     * - `tokenId` must not exist.
     */
    function safeMint(uint256 tokenId) 
        external 
        onlyRole(MINTER_ROLE) 
        notReachedMaxSupply 
        inRangeToken(tokenId) 
    {
        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @dev Creates a new token for a specific address.
     * @param to Address that will receive the token
     * @param tokenId ID of the token to be created
     *
     * Requirements:
     * - The caller must have the minter role.
     * - The max supply must not have been reached.
     * - `tokenId` must be greater than or equal to 0 and less than max supply.
     * - `tokenId` must not exist.
     */
    function safeMintFor(address to, uint256 tokenId)
        external
        onlyRole(MINTER_ROLE)
        notReachedMaxSupply
        inRangeToken(tokenId)
    {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Creates a new token for the caller upon payment of the set price.
     * @param tokenId ID of the token to be created
     *
     * Requirements:
     * - Contract must not be paused.
     * - The max supply must not have been reached.
     * - `tokenId` must be greater than or equal to 0 and less than max supply.
     * - The number of ETH sent must be greater than or equal to the buy price.
     * - `tokenId` must not exist.
     */
    function buy(uint256 tokenId) external payable whenNotPaused notReachedMaxSupply inRangeToken(tokenId) {
        require(msg.value >= _buyPrice, "Not enough ETH");
        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @dev Transfers all funds in the contract to the caller.
     */
    function withdraw() external onlyRole(COLLECTOR_ROLE) {
        uint256 amount = getBalance();
        emit EtherWithdrawn(_msgSender(), amount);
        Address.sendValue(payable(_msgSender()), amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}