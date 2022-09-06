// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Sazuki is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;  
    uint public price = 500000000000000; 
    uint public maxPerTx = 30; 
    uint public maxPerWallet = 60;
    uint public totalFree = 2000;
    uint public maxSupply = 9999;
    uint public freeMint = 5;
    bool public mintStart = true;
    mapping (address => uint256) public addressMint;

    constructor() ERC721A("Sazuki", "Sazuki"){}

    function mint(uint256 amount) external payable
    {
        uint cost = price;
        if(msg.value == 0 && totalSupply() + amount <= totalFree) 
        {
           require(addressMint[msg.sender] + amount <= freeMint,"Sazuki Limit Claimed");
           addressMint[msg.sender] += amount;
           cost = 0;
        }
        require(msg.value >= amount * cost,"Sazuki Limit Insufficient Funds");
        require(mintStart, "Sazuki Limit Minting Pause");
        require(amount <= maxPerTx, "Sazuki Limit Per Transaction");
        require(totalSupply() + amount <= maxSupply,"Sazuki  Soldout");
        require(numberMinted(msg.sender) + amount <= maxPerWallet,"Sazuki Limit Wallet");
        _safeMint(msg.sender, amount);
    }

    function toggleMintingSazuki() external onlyOwner {
        mintStart = !mintStart;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPriceSazuki(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setTotalFreeSazuki(uint256 totalFree_) external onlyOwner {
        totalFree = totalFree_;
    }
    function setFreeMintSazuki(uint256 freeMint_) external onlyOwner {
        freeMint = freeMint_;
    }

    function setMaxPerTxSazuki(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxPerWalletSazuki(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setmaxSupplySazuki(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdropSazuki(address to ,uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= maxSupply,"Soldout");
        _safeMint(to, amount);
    }

    function ownerMintSazuki(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= maxSupply,"Soldout");
        _safeMint(msg.sender, amount);
    }
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}