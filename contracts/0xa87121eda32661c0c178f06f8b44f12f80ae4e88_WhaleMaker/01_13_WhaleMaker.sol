// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhaleMaker is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant WHALE_AIRDROP = 52;
    uint256 public constant WHALE_PUBLIC = 948;
    uint256 public constant WHALE_MAX = WHALE_AIRDROP + WHALE_PUBLIC;
    uint256 public constant WHALE_MAX_TX = 2;
    uint256 public constant MINT_PRICE = 0.5 ether;
    
    uint256 public airdropCounter;
    uint256 public publicSaleCounter;
    string public provenance;
    bool public live;
    bool public locked;
    string private _baseDataURI;
    
    constructor() ERC721("Whale Maker", "WHALE") { }
    
    function airdrop(address[] calldata airdrops) external onlyOwner {
        require(airdropCounter < WHALE_AIRDROP, "MAX_AIRDROPS_GIVEN");
        
        for(uint256 i = 0; i < airdrops.length; i++) {
            airdropCounter++;
            _safeMint(airdrops[i], totalSupply() + 1);
        }
    }
    
    function buy(uint256 num) external payable {
        require(live, "CLOSE_SALE");
        require(totalSupply() < WHALE_MAX, "SOLD_OUT");
        require(publicSaleCounter + num < WHALE_PUBLIC, "SALE_DONE");
        require(num <= WHALE_MAX_TX, "EXCEEDS_MAX_MINT");
        require(MINT_PRICE * num <= msg.value, "NOT_ENOUGH_PAID");
        
        for(uint256 i = 0; i < num; i++) {
            publicSaleCounter++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function toggleSaleStatus() external onlyOwner {
        live = !live;
    }
    
    function setHash(string calldata hash) external onlyOwner {
        provenance = hash;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseDataURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_baseDataURI, tokenId.toString()));
    }
}