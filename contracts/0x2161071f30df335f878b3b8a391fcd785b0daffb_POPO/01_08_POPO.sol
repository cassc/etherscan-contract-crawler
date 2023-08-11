// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


contract POPO is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2023;

    uint256 public maxPerTx = 7;

    uint256 public priceTier1 = 0.03 ether;
    uint256 public priceTier2 = 0.08 ether;
  
    string public baseURI = "ipfs://bafybeia7jux4prgptenmu6b6bsp33ed53h6esgj6d2j5gxa3rfzvg3ghla/";
    string public hiddenURI = "";
   
    bool public mintEnabled = false;
    bool public isRevealed = true;

    constructor() ERC721A("POPO", "POPO") {
        _safeMint(msg.sender, 10);
    }
    

    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, "Yo!!!");
        require(mintEnabled, "Minting is not live yet.");
        require(amount > 0 && amount <= maxPerTx, "Invalid amount.");
        require(totalSupply() + amount <= maxSupply, "No more");

        uint256 cost;
        uint256 currentSupply = totalSupply();

        if (currentSupply < 500) {
            uint256 remainingFirstTier = 500 - currentSupply;

            if (amount <= remainingFirstTier) {
                cost = priceTier1 * amount;
            } else {
                uint256 firstTierAmount = remainingFirstTier;
                uint256 secondTierAmount = amount - remainingFirstTier;
                cost = (priceTier1 * firstTierAmount) + (priceTier2 * secondTierAmount);
            }
        } else {
            cost = priceTier2 * amount;
        }

        require(msg.value >= cost, "Insufficient funds.");

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, 1);
        }
    }
 

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }
    function setRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistenttoken');

       if(isRevealed==false)
        return hiddenURI;

        return
            string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Set price tier 1
    function setPriceTier1(uint256 _priceTier1) external onlyOwner {
        priceTier1 = _priceTier1;
    }

    // Set price tier 2
    function setPriceTier2(uint256 _priceTier2) external onlyOwner {
        priceTier2 = _priceTier2;
    }
  
    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
   
   
}