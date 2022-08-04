// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Tiffbird is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;  
    uint public price = 1000000000000000; //0.001 ETH
    uint public maxPerTx = 7; 
    uint public maxPerWallet = 35;
    uint public totalFree = 1777;
    uint public maxSupply = 7777;
    uint public freeMint = 5;
    bool public mintEnabled = true;
    mapping (address => uint256) public addressMint;

    constructor() ERC721A("Tiffbirds", "Tiffbirds"){}

    function mint(uint256 amount) external payable
    {
        uint cost = price;
        if(msg.value == 0 && totalSupply() + amount <= totalFree) 
        {
           require(addressMint[msg.sender] + amount <= freeMint,"Tiffbirds - Claimed");
           addressMint[msg.sender] += amount;
           cost = 0;
        }
        require(msg.value == amount * cost,"Tiffbirds - Insufficient Funds");
        require(mintEnabled, "Tiffbirds - Minting Pause");
        require(amount <= maxPerTx, "Tiffbirds - Limit Per Transaction");
        require(totalSupply() + amount <= maxSupply,"Tiffbirds - Soldout");
        require(numberMinted(msg.sender) + amount <= maxPerWallet,"Tiffbirds - Max Per Wallet");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address to ,uint256 amount) external onlyOwner
    {
        _safeMint(to, amount);
    }

    function ownerBatchMint(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= maxSupply,"too many!");

        _safeMint(msg.sender, amount);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
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

    function setTotalFree(uint256 totalFree_) external onlyOwner {
        totalFree = totalFree_;
    }
    function setFreeMint(uint256 freeMint_) external onlyOwner {
        freeMint = freeMint_;
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

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}