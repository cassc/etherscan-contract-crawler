//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeFolks is ERC721A, Ownable {
    uint256 public mintPrice;
    uint256 public maxPerWallet;

    uint256 public supply;
    uint256 public maxSupply;
    
    bool public isMintEnabled;
    
    string internal baseTokenUri;

    address payable public withdrawalWallet;

    mapping(address => uint256) public walletMints;


    constructor(string memory _baseUri) ERC721A("PepeFolks", "PEPEFLKS") {
        mintPrice = 0.0033 ether;
        maxSupply = 3333;
        maxPerWallet = 5;

        isMintEnabled = false;
        
        baseTokenUri = _baseUri;
    }

    function totalSupply() public view override returns (uint256) {
        return supply;
    }
    function setSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }
    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }
    function setMintPrice(uint256 mintPriceWei_) external onlyOwner {
        mintPrice = mintPriceWei_;
    }
    function setPublicMintEnabled(bool isMintEnabled_) external onlyOwner {
        isMintEnabled = isMintEnabled_;
    }
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
    
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Token with such ID does not exist");
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }
    function withdraw() external onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}('');
        require(success, "Withdraw failed");
    }

    function mint(uint256 quantity_) public payable {
        require(isMintEnabled, "Not mintable yet");
        require(msg.value == quantity_ * mintPrice, "Wrong mint value");
        require(supply + quantity_ <= maxSupply, "Sold out");
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "Wallet limit exceeded");
        
        _safeMint(msg.sender, quantity_);
        walletMints[msg.sender] += quantity_;
        supply += quantity_;
    }
    
    function airdrop(uint256 quantity_) public onlyOwner {
        require(supply + quantity_ <= maxSupply, "Supply exceed");
        supply += quantity_;
        _safeMint(msg.sender, quantity_);
    }
}