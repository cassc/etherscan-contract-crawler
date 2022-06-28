// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import './ERC721A.sol';

/**
 * @title Kodaz contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract Kodaz is Ownable, ERC721A {
    uint256 public constant maxSupply = 10000;
    uint256 public freeAmount = 500;

    uint32 public saleStartTime = 0;

    constructor() ERC721A("KODAZ", "KODAZ") {}

    uint256 public mintPrice = 0.01 ether;
    uint256 public maxFreeMintPerWallet = 2;
    uint256 public maxAmountPerMint = 10;

    address private wallet1 = 0xED44447e2d312EF905D1167669E604067d0D91FA;
    address private wallet2 = 0xA5344090f9eb84B18564ab3e44b4637ceeB6Cd4c;
    address private wallet3 = 0x7A4AFBf4a877FF05b2C415Ab8EC457b08ED02793;
    address private wallet4 = 0xF5caf09F580c42AfebcF3125637e047F8126c61c;

    function setSaleStartTime(uint32 newFreeAmount) public onlyOwner {
        freeAmount = newFreeAmount;
    }

    function setFreeAmount(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxAmountPerMint(uint256 newMaxAmountPerMint) external onlyOwner {
        maxAmountPerMint = newMaxAmountPerMint;
    }

    function setMaxFreeMintPerWallet(uint256 newMaxFreeMintPerWallet) external onlyOwner {
        maxFreeMintPerWallet = newMaxFreeMintPerWallet;
    }

    /**
     * metadata URI
     */
    string private _baseURIExtended = "";

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(wallet1), balance * 57 / 100);
        Address.sendValue(payable(wallet2), balance * 20 / 100);
        Address.sendValue(payable(wallet3), balance * 20 / 100);
        Address.sendValue(payable(wallet4), address(this).balance);
    }

    /**
     * reserve
     */
    function reserve(address account, uint256 amount) public onlyOwner {
        require(amount <= maxAmountPerMint, "Exceeded max token purchase");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        
        _safeMint(account, amount);
    }

    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(saleStartTime != 0 && saleStartTime <= block.timestamp, "Sales is not started");        
        require(totalSupply() < maxSupply, "Exceeds max supply");

        uint256 mintableAmount;

        if(totalSupply() < freeAmount) {
            require(balanceOf(msg.sender) < maxFreeMintPerWallet, "Free mint limit per wallet reached");

            uint256 availableFreeSupply = freeAmount - totalSupply();
            uint256 availableFreeMintAmount = maxFreeMintPerWallet - balanceOf(msg.sender);
            mintableAmount = Math.min(amount, availableFreeMintAmount);
            mintableAmount = Math.min(mintableAmount, availableFreeSupply);

            require(mintableAmount > 0, 'Nothing to free mint');

            _safeMint(msg.sender, mintableAmount);

            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
        } else {
            require(amount <= maxAmountPerMint, "Exceeded max token purchase");
            uint256 availableSupply = maxSupply - totalSupply();
            mintableAmount = Math.min(amount, availableSupply);

            uint256 totalMintCost = mintableAmount * mintPrice;
            require(msg.value >= totalMintCost, "Not enough ETH sent; check price!"); 

            _safeMint(msg.sender, mintableAmount);

            // Refund unused fund
            uint256 changes = msg.value - totalMintCost;
            if (changes != 0) {
                Address.sendValue(payable(msg.sender), changes);
            }                
        }
    }
}