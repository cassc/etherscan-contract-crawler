// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract WorldWidePunks is ERC721Enumerable, Ownable{ //mainnet version 21/09/2022
  using SafeMath for uint256;
  using Strings for string;
  // Storage Game Variables
  address t1 = 0x2a6C2E0fC8489335e826997cedaf34878c26d1cE; // DEV
  address t2 = 0x9593a0eB982708D08fF05181864279152D81baa3; // Droplist friend
  address t3 = 0x4fb8b7C9a19E6e5DA054A9ea20308C90531652Ff; // DropList
  //NFT Variables
  uint256 public PunkPrice = 20000000000000000; // 0.02 ETH
  uint public constant maxPunkPurchase = 20;
  uint256 public MAX_Punks = 2500;
  bool public saleIsActive = false;
  string _baseTokenURI = "https://super-nft-collections.s3.eu-west-1.amazonaws.com/WorldWidePunks/json/";
  bool public forceIsActive = false;
  constructor() ERC721("WorldWidePunks", "WWP") {
    }

  function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

  function flipForce() public onlyOwner {
      forceIsActive = !forceIsActive;
    }

  function setPrice(uint256 _newPrice) public onlyOwner() { 
        PunkPrice = _newPrice;
    }

  function getPrice() public view returns (uint) {
    return PunkPrice; 
  }

  function withdrawAll() public payable onlyOwner {
        uint256 funds = address(this).balance.div(20);
        require(payable(t1).send(funds*14));
        require(payable(t2).send(funds*3));
        require(payable(t3).send(funds*3));
        
    }

  function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

  function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
    }

  function mintPunks(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Punks");
        require(numberOfTokens <= maxPunkPurchase, "Maximum mints per transaction exceeded");
        require(totalSupply().add(numberOfTokens) <= MAX_Punks, "Purchase would exceed max supply of Punks");
        require(PunkPrice.mul(numberOfTokens) == msg.value, "Ether value sent is not correct");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_Punks) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

  function jediForce() public {
      require(saleIsActive, "Sale must be active to mint Punks");
      require(forceIsActive, "Only authorized wallets can use this jedi function");
      require(totalSupply().add(1) <= MAX_Punks, "Purchase would exceed max supply of Punks");
      uint mintIndex = totalSupply();
      if (totalSupply() < MAX_Punks) {
          _safeMint(msg.sender, mintIndex);
      }
    }
}