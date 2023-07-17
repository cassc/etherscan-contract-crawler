// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PEPErHands is ERC721A, Ownable {
    bool public mintActive = false;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant PRICE = 0.0025 ether;
    uint256 public constant PER_WALLET = 10;
    uint256 public constant FREE = 2;
    string private baseUri = "uri";

    constructor(string memory uri) ERC721A("PEPErHands", "PPH") {
        baseUri = uri;
    }

    function publicMint(uint256 quantity, uint256 free) external payable {
        require(mintActive, "Sale not active");
        require(msg.sender == tx.origin, "Only Human");
        require(balanceOf(msg.sender) + quantity + free <= PER_WALLET, "Mint limit per wallet");
        require(totalSupply() + quantity + free <= MAX_SUPPLY, "Total supply reached");
        if (free != 0) {
            require(totalSupply() + free <= FREE, "You can't mint more for free");
        }
        require(PRICE * quantity <= msg.value, "Insufficient funds sent");
        _mint(msg.sender, quantity + free);
    }

    function airdrop(uint256 quantity, address to) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Total supply reached");
        _mint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function flipMintState() external onlyOwner {
        mintActive = !mintActive;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }
}