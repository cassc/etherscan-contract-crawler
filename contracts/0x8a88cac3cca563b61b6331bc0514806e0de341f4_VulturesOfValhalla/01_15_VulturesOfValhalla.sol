//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract VulturesOfValhalla is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI = "ipfs://QmXZDpnjfMv24toSXzxyLaC13uyDxXQmqy7etmxTW6y5mU/";
    uint   public price             = 0.0022 ether;
    uint   public maxPerTx          = 5;
    uint   public maxPerFree        = 2;
    uint   public maxPerWallet      = 20;
    uint   public totalFree         = 3333;
    uint   public maxSupply         = 3333;
    bool   public mintEnabled;
    uint   public totalFreeMinted = 0;

    mapping(address => uint256) public _mintedFreeAmount;
    mapping(address => uint256) public _totalMintedAmount;

    constructor() ERC721A("Vultures of Valhalla", "VOV"){}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,Strings.toString(_tokenId+1),".json"))
            : "";
    }
    

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalFreeMinted + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] < maxPerFree));

        if (isFree) { 
            require(mintEnabled, "Mint is not live yet");
            require(totalSupply() + count <= maxSupply, "No more");
            require(count <= maxPerTx, "Max per TX reached.");
            if(count >= (maxPerFree - _mintedFreeAmount[msg.sender]))
            {
             require(msg.value >= (count * cost) - ((maxPerFree - _mintedFreeAmount[msg.sender]) * cost), "Please send the exact ETH amount");
             _mintedFreeAmount[msg.sender] = maxPerFree;
             totalFreeMinted += maxPerFree;
            }
            else if(count < (maxPerFree - _mintedFreeAmount[msg.sender]))
            {
             require(msg.value >= 0, "Please send the exact ETH amount");
             _mintedFreeAmount[msg.sender] += count;
             totalFreeMinted += count;
            }
        }
        else{
        require(mintEnabled, "Mint is not live yet");
        require(_totalMintedAmount[msg.sender] + count <= maxPerWallet, "Exceed maximum NFTs per wallet");
        require(msg.value >= count * cost, "Please send the exact ETH amount");
        require(totalSupply() + count <= maxSupply, "No more");
        require(count <= maxPerTx, "Max per TX reached.");
        require(msg.sender == tx.origin, "The minter is another contract");
        }
        _totalMintedAmount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function costCheck() public view returns (uint256) {
        return price;
    }

    function maxFreePerWallet() public view returns (uint256) {
      return maxPerFree;
    }

    function burn(address mintAddress, uint256 count) public onlyOwner {
        _safeMint(mintAddress, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxTotalFree(uint256 MaxTotalFree_) external onlyOwner {
        totalFree = MaxTotalFree_;
    }

     function setMaxPerFree(uint256 MaxPerFree_) external onlyOwner {
        maxPerFree = MaxPerFree_;
    }

    function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
    }
    
    function CommunityWallet(uint quantity, address user)
    public
    onlyOwner
  {
    require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(user, quantity);
  }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}