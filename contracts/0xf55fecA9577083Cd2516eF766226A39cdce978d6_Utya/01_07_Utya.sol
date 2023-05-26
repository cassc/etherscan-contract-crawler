//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Utya is Ownable, ReentrancyGuard, ERC721A {
    string private _URI;
    bool private _paused = true;

    uint256 public constant totalSupplyLimit = 2000;
    uint256 public constant transactionLimit = 50;
    uint256 public adminMintLimit = 200; //reserved for sudoswap
    uint256 public adminMinted = 0;
    uint256 constant baseMintPrice = 0.05 ether;
    uint256 constant smallDiscountPrice = 0.04 ether;
    uint256 constant bigDiscountPrice = 0.03 ether;
    uint256 constant smallDiscountCutoff = 5;
    uint256 constant bigDiscountCutoff = 10;

    constructor() ERC721A("Utya", "UTYA") {} 

    function mint(uint256 numTokens) payable external nonReentrant {
        require(_paused == false, "Minting is paused");
        require(numTokens <= transactionLimit, "Max 50 per transaction");
        require(totalSupply() + numTokens <= totalSupplyLimit, "Total supply exceeded");
        
        uint256 totalPrice = getPrice(numTokens);

        require(msg.value == totalPrice, "Incorrect price");

        _safeMint(msg.sender, numTokens);
    }

    function adminMint(uint256 numTokens) external onlyOwner {
        require(adminMinted + numTokens <= adminMintLimit, "Admin mint limit exceeded");
        _safeMint(msg.sender, numTokens);
        adminMinted += numTokens;
    }

    function switchPause() public onlyOwner() {
        _paused = !_paused;
    }

    function setURI(string memory uri) public onlyOwner() {
        _URI = uri;
    }

    function setAdminMintLimit(uint256 limit) public onlyOwner() {
        adminMintLimit = limit;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'tokenId empty');
        return string(abi.encodePacked(_URI, _toString(tokenId)));
    }

    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function getPrice(uint256 numTokens) public view returns (uint256) {
        if (numTokens < smallDiscountCutoff) {
            return (numTokens * baseMintPrice);
        } else if (numTokens < bigDiscountCutoff) {
            return (numTokens * smallDiscountPrice);
        } else {
            return (numTokens * bigDiscountPrice);
        }
    }
}