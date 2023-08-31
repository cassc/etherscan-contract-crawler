// SPDX-License-Identifier: MIT
// Created by https://blockgeni3.com for Fire Force NFT x RedBean Coffee

pragma solidity ^0.8.18;

import "https://raw.githubusercontent.com/chiru-labs/ERC721A/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FireForce is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string internal baseURI;
    string internal notRevealedURI;

    uint256 public constant maxSupply = 1000;
    uint256 public cost = 17000000000000000; // 0.017 ether in Wei

    bool public publicMintStarted = false;
    bool internal revealedState = false;

    address payable public immutable Blockgeni3Address;
    address payable public immutable FireForceAddress;

    constructor(string memory _initBaseURI, string memory _initNotRevealedURI) ERC721A("Fire Force x Red Bean Coffee", "FFRBC") {
        baseURI = _initBaseURI;
        notRevealedURI = _initNotRevealedURI;
        Blockgeni3Address = payable(0xBB92a3435b045193bbbD62BaC01D64125202d706);
        FireForceAddress = payable(0x4AF654d7eA4E4eB0d0A9D94E65cD1C91eFE2129B);
    }

    function devMint(uint8 quantity) external onlyOwner checkSupply(quantity) {
        _mint(msg.sender, quantity);
    }

    function mint(uint8 quantity) external payable nonReentrant whenPublicMint checkSupply(quantity) {
        require(msg.value >= cost * quantity, "[Value Error] Not enough funds supplied for mint");
        _mint(msg.sender, quantity);
        sendFunds(address(this).balance);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return revealedState ? string(baseURI) : string(notRevealedURI);
    }

    function toggleMintStatus() external onlyOwner {
        publicMintStarted = !publicMintStarted;
    }

    function toggleReveal() external onlyOwner {
        revealedState = !revealedState;
    }

    function setMintPrice(uint256 value) external onlyOwner {
        cost = value;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        sendFunds(address(this).balance);
    }

    function sendFunds(uint256 _totalAmount) internal {
        uint256 fireForceShare = _totalAmount * 3 / 4;
        uint256 blockgeni3Share = _totalAmount / 4;

        FireForceAddress.transfer(fireForceShare);
        Blockgeni3Address.transfer(blockgeni3Share);
    }

    modifier whenPublicMint() {
        require(publicMintStarted, "[Mint Status Error] Public mint not active.");
        _;
    }

    modifier checkSupply(uint8 quantity) {
        require(totalSupply() + quantity <= maxSupply, "[Supply Error] Exceeds max supply.");
        _;
    }

    receive() external payable nonReentrant {
        sendFunds(msg.value);
    }
}