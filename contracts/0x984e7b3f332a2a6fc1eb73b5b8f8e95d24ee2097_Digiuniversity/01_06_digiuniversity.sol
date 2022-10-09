// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract Digiuniversity is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2822;

    uint256 public maxFreeAmount = 1000;

    uint256 public maxFreePerTx = 5;
    
    uint256 public maxFreePerWallet = 1;
    
    uint256 public maxPerTx = 5;
    
    
    uint256 public price = 0.02 ether;

    
    string public baseURI = "";
    string public hiddenURI = "";
    
   
    bool public mintEnabled = false;
    bool public isRevealed = true;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Digiuniversity", "DUY") {
        _safeMint(msg.sender, 15);
    }
    

    function mint(uint256 amount) external payable {
        uint256 cost = price;
        uint256 num = amount > 0 ? amount : 1;
        bool free = ((totalSupply() + num < maxFreeAmount + 1) &&
            (_mintedFreeAmount[msg.sender] + num <= maxFreePerWallet));
        if (free) {
            cost = 0;
            _mintedFreeAmount[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < maxPerTx + 1, "Max per TX reached.");
        }
        require(tx.origin == msg.sender, "Yo!!!");
        require(mintEnabled, "Minting is not live yet.");
        require(msg.value <= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < maxSupply + 1, "No more");

        _safeMint(msg.sender, num);
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
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

   if(isRevealed==false)
    return hiddenURI;

    return
      string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
  }
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function setMaxFreePerTx(uint256 _amount) external onlyOwner {
        maxFreePerTx = _amount;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
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