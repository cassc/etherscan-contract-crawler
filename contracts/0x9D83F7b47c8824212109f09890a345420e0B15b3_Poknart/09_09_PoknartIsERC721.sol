// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC721A.sol";

contract Poknart is Ownable, ERC721A, ReentrancyGuard {
    constructor(string memory _baseUri, string memory _notRevealedUri) ERC721A("Poknart", "POKNART"){
        transferOwnership(msg.sender);
        baseUri = _baseUri;
        notRevealedUri = _notRevealedUri;
    }

    using Strings for uint;

    uint private constant MAX_SUPPLY = 3000;
    uint public constant PRICE_PUBLIC = 0.040 ether;
    uint private constant MAX_PER_ADDRESS = 3;

    bool public revealed = false;
    string public baseUri;
    string public notRevealedUri;
    string public baseExtension = ".json";

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setNotRevealedURI(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseUri;
    }

    function reveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function mint(uint _quantity) external payable callerIsUser {
        require(msg.value >= PRICE_PUBLIC * _quantity, "Not enough funds");
        require(_quantity != 0, "You can't mint 0 poke");
        require(_numberMinted(msg.sender) + _quantity <= MAX_PER_ADDRESS, "You can't mint more than 3 NFTs");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(msg.sender, _quantity);
    }

    function tokenURI(uint _tokenId) public view virtual override(ERC721A) returns(string memory) {
        require(_exists(_tokenId), "NFT not minted");
        if(revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseUri = _baseURI();
        return bytes(currentBaseUri).length > 0 ? string(abi.encodePacked(currentBaseUri, _tokenId.toString(), baseExtension)) : "";
    }

    function withdrawMoney() external onlyOwner nonReentrant{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}