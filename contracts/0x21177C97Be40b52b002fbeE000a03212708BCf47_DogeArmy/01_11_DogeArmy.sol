// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract DogeArmy is ERC721, Ownable {
    using Strings for uint256;

    ERC20 immutable private SHIB_DOGE;

    uint256 constant public MAX_DOGE = 10000;
    uint256 constant public MAX_DOGE_PER_TXNS = 20;
    uint256 constant public MAX_DOGE_PER_WHITELIST = 10;
    uint256 constant public MAX_RESERVED = 100;
    
    // constant as this will not change
    uint256 constant public PRESALE_PRICE = 0.1 ether;
    // this could change
    uint256 public publicPrice = 0.15 ether;

    uint256 public totalSupply;
    uint256 public minTokenThreshold = 517606000000000000; // includes 9 decimals

    bool public isPresale;
    bool public isPublicSale;
    bool public isURIFrozen;
    bool public revealed;

    uint256 private reserved;
    mapping(address => uint256) private presaleMints;

    uint256[] public provenanceIds;
    
    string public unrevealedURI = "https://dogearmy.mypinata.cloud/ipfs/QmT5tyCujQeuJa3ya7V6Gyxm5F6QysLiQAtuyXrtgh9jDZ";
    string public baseURI;

    constructor(ERC20 _shibDoge) ERC721("DogeArmy", "DA") {
        SHIB_DOGE = _shibDoge;
    }

    function mint(uint256 amount) public payable {
        require(isPublicSale, "Public Sale Inactive");
        require(amount > 0, "Number of tokens should be more than 0");

        require(amount <= MAX_DOGE_PER_TXNS, "Mint Overflow");
        require(totalSupply + amount <= MAX_DOGE, "Sold Out");
        require(publicPrice * amount <= msg.value, "Insufficient Funds");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++totalSupply);
        }
    }

    function mintPresale(uint256 amount) public payable {
        require(isPresale, "Pre Sale Inactive");
        require(amount > 0, "Number of tokens should be more than 0");
        require(totalSupply + amount <= MAX_DOGE, "Sold Out");
        require(PRESALE_PRICE * amount <= msg.value, "Insufficient Funds"); 
        require(presaleMints[msg.sender] + amount <= MAX_DOGE_PER_WHITELIST, "Max NFT per Address Exceeded in presale");
        
        uint256 balanceOf = SHIB_DOGE.balanceOf(msg.sender);
        require(balanceOf >= minTokenThreshold, "token balance is not enough");

        presaleMints[msg.sender] += amount;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++totalSupply);
        }
    }

    // Owner functions 

    function reserve(uint256 amount, address destination) external onlyOwner {
        require(amount > 0, "cannot mint 0");
        require(amount <= MAX_DOGE_PER_TXNS, "Mint Overflow");
        require(totalSupply + amount <= MAX_DOGE, "Sold Out");
        require(reserved + amount <= MAX_RESERVED, "Exceeds maximum number of reserved tokens");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(destination, ++totalSupply);
        }

        reserved += amount;
    }
    
    function setMinTokenThreshold(uint256 _minTokenThreshold) external onlyOwner {
        minTokenThreshold = _minTokenThreshold;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function togglePreSale() external onlyOwner {
        isPresale = !isPresale;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function freezeURI() external onlyOwner {
        isURIFrozen = true;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setUnrevealedURI(string calldata _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        baseURI = _newBaseURI;
    }

    function addProvenance(uint256 id) external onlyOwner {
        provenanceIds.push(id);
    }

    // view/pure functions
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) {
            return unrevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) 
            : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}