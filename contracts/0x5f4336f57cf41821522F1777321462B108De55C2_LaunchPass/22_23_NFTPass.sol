// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import {ITokenRenderer} from "./ITokenRenderer.sol";
import {SignedAllowlist} from "../SignedAllowlist.sol";

contract NFTPass is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Pausable, Ownable, SignedAllowlist {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 private _maxSupply = 0;
    uint256 private _mintPrice = 0 ether;
    uint256 private _maxPerWallet = 1;
    address private _tokenRendererAddress;
    bool private _isTokenRendererFrozen;
    bool private _isPublicMintEnabled;
    string private _contractUriJSON;

    constructor(address tokenRendererAddress, address whitelistSigningKey, string memory contractUriJSON, string memory name, string memory symbol) public ERC721(name, symbol) SignedAllowlist(name, whitelistSigningKey) {
        _tokenRendererAddress = tokenRendererAddress;
        _contractUriJSON = contractUriJSON;
    }

    // Contract URI
    function setContractUriJSON(string memory contractUriJSON) public onlyOwner {
        _contractUriJSON = contractUriJSON;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(
                    abi.encodePacked(
                        _contractUriJSON
                    )
                ))
            )
        );
    }

    // Max per wallet
    function setMaxPerWallet(uint256 maxPerWallet) public onlyOwner {
        _maxPerWallet = maxPerWallet;
    }

    function maxPerWallet() public view returns (uint256) {
        return _maxPerWallet;
    }

    // Max supply
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        _maxSupply = maxSupply;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    // Price
    function setMintPrice(uint256 mintPrice) public onlyOwner {
        _mintPrice = mintPrice;
    }

    function mintPrice() public view returns (uint256){
        return _mintPrice;
    }

    // Public mint
    function setPublicMintEnabled(bool enabled) public onlyOwner {
        _isPublicMintEnabled = enabled;
    }

    function publicMintEnabled() public view returns (bool) {
        return _isPublicMintEnabled;
    }

    // Token renderer
    modifier whenTokenRendererNotFrozen() {
        require(!_isTokenRendererFrozen, "URI getter is frozen");
        _;
    }

    function freezeTokenRenderer() public onlyOwner {
        _isTokenRendererFrozen = true;
    }

    function setTokenRendererAddress(address tokenRenderer) public onlyOwner whenTokenRendererNotFrozen {
        _tokenRendererAddress = tokenRenderer;
    }

    // Mint
    function _mintToken(address to) internal returns (uint256) {
        require(balanceOf(to) <= (_maxPerWallet - 1), "Exceeds amount of passes per person");

        uint256 tokenId = _tokenIdCounter.current();

        if (_maxSupply != 0) {
            require(tokenId < _maxSupply, "Max supply reached");
        }

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        return tokenId;
    }

    function _mintTokenCheckPrice(address to) internal {
        if (_mintPrice != 0) {
            require(msg.value == _mintPrice, "Transaction value did not equal to mint price");
        }

        address to = _msgSender();
        _mintToken(to);
    }

    function safeMint(address to) public onlyOwner {
        _mintToken(to);
    }

    function mint() public whenNotPaused payable {
        require(_isPublicMintEnabled == true, "Public mint is not enabled");
        _mintTokenCheckPrice(_msgSender());
    }

    function allowlistMint(bytes calldata signature) public whenNotPaused requiresAllowlist(signature) payable
    {
        _mintTokenCheckPrice(_msgSender());
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
    {
        _requireMinted(tokenId);
        ITokenRenderer template = ITokenRenderer(_tokenRendererAddress);
        return template.getTokenURI(tokenId, name());
    }

    // Payments
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

    // ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}