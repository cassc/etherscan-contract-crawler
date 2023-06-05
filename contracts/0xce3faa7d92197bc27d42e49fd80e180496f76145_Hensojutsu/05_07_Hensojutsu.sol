// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
Good Ninja hides in the shadow. 
Legendary Ninja becomes a shadow. Welcome to the world of Legendary Ninjas
Kiai!

https://twitter.com/HensojutsuNFT
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hensojutsu is ERC721A, Ownable {
    uint256 public mintPrice;

    uint256 public maxPerWallet;
    uint256 public freePerWallet;

    uint256 public maxSupply;
    
    bool public isMintEnabled;
    
    string internal baseTokenUri;


    constructor(string memory _baseUri) ERC721A("Hensojutsu", "HNSOTS") {
        mintPrice = 0.004 ether;
        maxSupply = 4000;
        maxPerWallet = 6;
        freePerWallet = 1;

        isMintEnabled = false;
        
        baseTokenUri = _baseUri;
    }

    // ONLY OWNER
    function setSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }
    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }
    function setFreePerWallet(uint256 freePerWallet_) external onlyOwner {
        freePerWallet = freePerWallet_;
    }
    function setMintPrice(uint256 mintPriceWei_) external onlyOwner {
        mintPrice = mintPriceWei_;
    }
    function setMintEnabled(bool isMintEnabled_) external onlyOwner {
        isMintEnabled = isMintEnabled_;
    }
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
    
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Token with such ID does not exist");
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_ + 1), ".json"));
    }
    
    function mint(uint256 quantity_) public payable {
        require(isMintEnabled, "Not mintable yet");
        require(totalSupply() + quantity_ <= maxSupply, "Sold out");
        require(msg.sender == tx.origin, "Only human");
        require(_numberMinted(msg.sender) + quantity_ <= maxPerWallet, "Wallet limit exceeded");
        
        if (_numberMinted(msg.sender) == 0) {
            if (quantity_ > 1){
                require(mintPrice * (quantity_ - freePerWallet) <= msg.value, "Insufficient funds (free included)");
            }
        } else {
            require(mintPrice * quantity_ <= msg.value, "Insufficient funds");
        }
        _safeMint(msg.sender, quantity_);
    }
    function airdrop(uint256 quantity_) public onlyOwner {
        require(totalSupply() + quantity_ <= maxSupply, "Supply exceed");
        _mint(msg.sender, quantity_);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}('');
        require(success, "Withdraw failed");
    }
}