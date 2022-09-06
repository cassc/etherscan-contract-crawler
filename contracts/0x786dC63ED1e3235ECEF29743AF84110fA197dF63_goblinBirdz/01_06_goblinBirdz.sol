// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract goblinBirdz is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;

    uint256 public price = 0.009 ether;
    uint256 public maxPerTx = 5;
    uint256 public maxPerWallet = 7;
    uint256 public maxSupply = 6969;
    uint256 public maxFree = 1;

    bool public publicSaleIsLive;

    mapping (address => uint256) public claimAvailable;

    constructor() ERC721A("GoblinBirdz", "GB")  {}

    function mint(uint256 amount) external payable {

        require(msg.sender == tx.origin, "You can't mint from a contract.");
        require(msg.value == amount * price, "Please send the exact amount in order to mint.");
        require(totalSupply() + amount <= maxSupply, "Better Luck next time, Sold out.");
        require(publicSaleIsLive, "Public sale is not live yet.");
        require(numberMinted(msg.sender) + amount <= maxPerWallet, "You have exceeded the mint limit per wallet.");
        require(amount <= maxPerTx, "You have exceeded the mint limit per transaction.");

        _safeMint(msg.sender, amount);
    }

    function claimFreeGoblinBirdz() external nonReentrant {
        
        require(claimAvailable[msg.sender] < maxFree);
        require(publicSaleIsLive, "Public sale is not live yet.");
        require(msg.sender == tx.origin);

        uint256 balance = balanceCheck(msg.sender);

        claimAvailable[msg.sender] += 1;

        if(claimAvailable[msg.sender] <= maxFree && balance >= 1) {
            claimAvailable[msg.sender] += 1;
        }

        uint256 amount = claimAvailable[msg.sender];

        require(totalSupply() + amount <= maxSupply, "Better Luck next time, Sold out.");
        require(numberMinted(msg.sender) + amount <= maxPerWallet, "You have exceeded the mint limit per wallet.");

        _safeMint(msg.sender, amount);
    }

    function ownerMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Can't mint");

        _safeMint(msg.sender, amount);
    }

    function toggleSaleState() external onlyOwner {
        publicSaleIsLive = !publicSaleIsLive;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }


    function setPrice(uint256 price_) external onlyOwner {
      price = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
      maxPerTx = maxPerTx_;
    } 

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      maxPerWallet = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function balanceCheck(address owner) public view returns (uint256) {
        return IERC721A(0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e).balanceOf(owner) +
               IERC721A(0x23581767a106ae21c074b2276D25e5C3e136a68b).balanceOf(owner);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}