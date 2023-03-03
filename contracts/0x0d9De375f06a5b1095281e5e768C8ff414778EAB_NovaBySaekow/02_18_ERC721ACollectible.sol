// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721AOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

// Custom Errors
error OutOfBounds();
error InvalidArgument();
error PaymentRequired(); // 402
error Conflict();        // 409
error InternalError();   // 500

contract ERC721ACollectible is ERC721AOperatorFilterer, Pausable, Ownable, ERC2981 {

// CONSTANTS

    uint256 public immutable TOKEN_MAX_SUPPLY;
    uint256 public immutable TOKEN_PRICE_WEI;
    uint256 public immutable TOKEN_MAX_PER_WALLET;

// VARIABLES

    bool private _isRevealed;
    string private _baseMetadataURI;

// INITIALIZATION

    constructor(string memory name_, string memory symbol_, uint256 maxSupply, uint256 priceWei, uint256 maxPerWallet)
        ERC721AOperatorFilterer(name_, symbol_)
    {
        _pause();

        TOKEN_MAX_SUPPLY = maxSupply;
        TOKEN_PRICE_WEI = priceWei;
        TOKEN_MAX_PER_WALLET = maxPerWallet;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId)
        ;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

// Modifiers

    modifier costs(uint256 price) {
        if (msg.value < price) revert PaymentRequired();
        _;
    }

    modifier hasMintsAvailable(uint256 quantity) {
        if (_numberMinted(msg.sender) + quantity > TOKEN_MAX_PER_WALLET) revert OutOfBounds();
        _;
    }

    modifier doesNotExceedMaxSupply(uint256 quantity) {
        if (totalSupply() + quantity > TOKEN_MAX_SUPPLY) revert OutOfBounds();
        _;
    }

// Minting

    function mint(uint128 quantity)
        external
        payable
        whenNotPaused
        doesNotExceedMaxSupply(quantity)
        costs(quantity * TOKEN_PRICE_WEI)
        hasMintsAvailable(quantity)
    {
        _mint(msg.sender, quantity);
    }

// Sale State

    function startSale() public onlyOwner {
        _unpause();
    }

    function stopSale() public onlyOwner {
        _pause();
    }

    function availableSupply() public view returns (uint256) {
        return TOKEN_MAX_SUPPLY - totalSupply();
    }

// Metadata

    function _baseURI() internal view override returns (string memory) {
        return _baseMetadataURI;
    }

    function setBaseURI(string calldata baseMetadataURI) external onlyOwner {
        _baseMetadataURI = baseMetadataURI;
    }

    function markRevealed(string calldata baseMetadataURI) external onlyOwner {
        _isRevealed = true;
        _baseMetadataURI = baseMetadataURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        return _isRevealed ? string(abi.encodePacked(baseURI, _toString(tokenId))) : baseURI;
    }

// Royalties

    function setRoyalties(address receiver, uint96 basisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, basisPoints);
    }

    function removeRoyalties() external onlyOwner {
        _deleteDefaultRoyalty();
    }

// Treasury

    function settleFunds() external onlyOwner {
        _withdrawEther(payable(owner()));
    }

    function _withdrawEther(address payable to) internal {
        (bool success, ) = to.call{value: address(this).balance}("");
        if (!success) revert InternalError();
    }
}