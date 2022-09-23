// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Whitelist} from "./Whitelist.sol";

contract ERC1155Base is ERC1155,  ERC1155Supply, ReentrancyGuard, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    Whitelist private whitelist;

    uint256 private MINT_PRICE = 0.01 ether;
    uint256 private MAX_SUPPLY = 10;
    bool private WHITELIST_ENABLED = true;
    mapping(uint256 => string) private _tokenURIs;
    string public name;
    string public symbol;

    constructor(address whitelistContract, string memory name_, string memory symbol_, uint256 price, uint256 maxSupply) public ERC1155("") {
        whitelist = Whitelist(whitelistContract);
        MINT_PRICE = price;
        MAX_SUPPLY = maxSupply;
        name = name_;
        symbol = symbol_;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setWhitelistEnabled(bool enabled) public onlyOwner {
        WHITELIST_ENABLED = enabled;
    }

    function getWhitelistEnabled(bool enabled) public view returns (bool) {
        return WHITELIST_ENABLED;
    }

    function setWhitelist(address whitelistContract) public onlyOwner {
        whitelist = Whitelist(whitelistContract);
    }

    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        MAX_SUPPLY = maxSupply;
    }

    function getMaxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        MINT_PRICE = price;
    }

    function getMintPrice() public view returns (uint256) {
        return MINT_PRICE;
    }

    function _mintToken(address recipient, string memory _tokenURI, uint256 amount, bytes memory data) internal virtual returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();

        require(amount > 0 && amount <= MAX_SUPPLY, "Amount should be more than 0 and less than MAX_SUPPLY");

        _tokenIdCounter.increment();
        _mint(recipient, tokenId, amount, data);
        _setTokenURI(tokenId, _tokenURI);

        return tokenId;
    }

    function isAddressWhitelisted(address walletAddress) public view returns (bool) {
        uint freeTokensCount = whitelist.checkWhitelistAddress(walletAddress);
        return freeTokensCount > 0;
    }

    function mintFree(address recipient, string memory _tokenURI, uint256 amount, bytes memory data) public virtual whenNotPaused {
        require(WHITELIST_ENABLED == true, "Whitelist is disabled");
        uint freeTokensCount = whitelist.checkWhitelistAddress(_msgSender());
        require(freeTokensCount > 0, "This wallet address can not mint free tokens");
        _mintToken(recipient, _tokenURI, amount, data);
        whitelist.setWhitelistAddress(Whitelist.WhitelistItem({walletAddress : _msgSender(), count : freeTokensCount - 1}));
    }

    function mint(address recipient, string memory _tokenURI, uint256 amount, bytes memory data) public virtual onlyOwner {
        _mintToken(recipient, _tokenURI, amount, data);
    }

    function mintTo(address recipient, string memory _tokenURI, uint256 amount, bytes memory data) public virtual whenNotPaused payable {
        require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price");
        _mintToken(recipient, _tokenURI, amount, data);
    }

    function withdrawPayments() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function payments() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}