// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract BoredGoats is ERC721A, Ownable {

    uint256 public mintPrice;
    uint256 public maxSupply;                           // total no. of NFTs
    uint256 public maxPerWallet;                        // max no. of NFTs per wallet
    bool public isMintEnabled;                          // for pausing and unpausing
    string internal baseURI;                            // main URI for collection
    mapping(address => uint256) public mintedWallets;   // Keeping track of No. of NFTs per wallet

    constructor() ERC721A("BoredGoats", "BG") {
       mintPrice = 0 ether;
       maxSupply = 1000;
       maxPerWallet = 2;
       baseURI = "ipfs://QmQutrUaeg84UbyuRsVYCyUyFVmqb28kgqDfLcQC9BHoHw/"; 
    }
    
    function mint( uint256 quantity_) public payable {
        require(isMintEnabled, 'Minting not enabled'); 
        require(msg.value >= (quantity_ * mintPrice), 'Wrong Mint Price');
        require(totalSupply() + quantity_ <= maxSupply , 'Not Enought NFTs left');
        require(_numberMinted(msg.sender) + quantity_ <= maxPerWallet, 'Exceeds Max per wallet'); 
        _safeMint(msg.sender, quantity_);       
    }

    function withdraw() external payable onlyOwner {
        (bool os, )= payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
    
    function setMintRate(uint256 mintPrice_) public onlyOwner {
        mintPrice = mintPrice_; // has to be in Wei
    }

    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 maxSupply_) onlyOwner external{
        maxSupply = maxSupply_;
    }
    function setMaxPerWallet(uint256 maxPerWallet_) onlyOwner external{
        maxPerWallet = maxPerWallet_;
    }
}