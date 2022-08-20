// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "base64-sol/base64.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import './ERC2981Base.sol';
import './NFT.sol';

contract PoopyInThePool is ERC721Enumerable, Ownable {
  event Mint(uint256 _tokenId);
  uint8 public constant MAX_FREE_MINT_PURCHASE = 10;
  uint16 public maxPoops;
  bool public saleIsActive = false;
  address payable public payoutAddress;
  uint16 public constant FREE_MINT_LIMIT = 1000;
  string private _baseURIextended;

  

  constructor(
    string memory name, 
    string memory symbol,
    uint16 maxNftSupply,
    string memory _initBaseURI,
    address payable _payoutAddress
  ) ERC721(name, symbol) {
    maxPoops = maxNftSupply;
    payoutAddress = _payoutAddress;
    _baseURIextended = _initBaseURI;
  }

  function withdraw() public onlyOwner {
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }

  function reservePoops() public onlyOwner {        
      uint256 mintIndex = totalSupply();
      for(uint8 i = 0; i < 200; i++) {
        _safeMint(msg.sender, mintIndex + i);
      }
  }

  function poopPrice() public view returns (uint256) {
      return _poopPrice();
  }

  function _poopPrice() internal view returns (uint256) {
      uint256 mintIndex = totalSupply();
      if(mintIndex <= FREE_MINT_LIMIT) {
          return 0 ether;   
      } else if (mintIndex < 3000) {
          return 0.02 ether;
      }
      return 0.04 ether;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseURIextended = baseURI;
  }

  function _maxPoops() public view returns (uint16) {
    return maxPoops;
  }

  function flipSaleState() public onlyOwner {
      saleIsActive = !saleIsActive;
  }

  function mintPoop(uint8 numberOfTokens) public payable {
      require(saleIsActive, "Sale must be active to mint");
      require((totalSupply() + numberOfTokens) <= maxPoops, "No more poops left");
      require((_poopPrice() * numberOfTokens) <= msg.value, "Ether value sent is not correct");

      if (totalSupply() < FREE_MINT_LIMIT) {
        require(numberOfTokens <= MAX_FREE_MINT_PURCHASE, "Max free mint purchase is 10");
        require((totalSupply() + numberOfTokens) <= FREE_MINT_LIMIT, "Not enough free tokens left");
      }

      for(uint8 i = 0; i < numberOfTokens; i++) {
          uint256 mintIndex = totalSupply();
          if (totalSupply() < maxPoops) {
            _safeMint(msg.sender, mintIndex);
            emit Mint(mintIndex);
          }
      }
  }
}