//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PiCipher is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public maxPerWallet;

    uint256 public totalSupply;
    uint256 public maxSupply;
    
    bool public isMintEnabled;
    
    string internal baseTokenUri;

    address payable public withdrawalWallet;

    mapping(address => uint256) public walletMints;

    constructor(string memory _baseUri) ERC721("PiCipher", "314") {
        mintPrice = 0.003140 ether;
        totalSupply = 0;
        maxSupply = 3141;
        maxPerWallet = 10;

        isMintEnabled = false;
        
        baseTokenUri = _baseUri;
    }

    function setSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }
    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }
    function setMintPrice(uint256 mintPriceWei_) external onlyOwner{
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
        require(totalSupply + quantity_ <= maxSupply, "Sold out");
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "Wallet limit exceeded");
        
        for(uint256 i = 0; i < quantity_; i++){
            walletMints[msg.sender] += 1;
            totalSupply++;
            _safeMint(msg.sender, totalSupply);
        }
    }
    
    function airdrop(uint256 quantity_) public onlyOwner {
        for(uint256 i = 0; i < quantity_; i++){
            totalSupply++;
            _safeMint(address(msg.sender), totalSupply);
        }
    }
}