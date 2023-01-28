// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract JZLNFT is ERC721A, Ownable {
  using Strings for uint256;

  string private baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 2000;
  uint64 publicSalePriceWei = 0.1 ether;
  bool public publicSaleStart = false;

  constructor(
    string memory _initBaseURI
  ) ERC721A("KhmerMaidens","KAC") {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public 
  function mint(address _to, uint256 _mintAmount) public payable {
    require(publicSaleStart,"mint not start");
    require(_mintAmount > 0,"mint amount greater than zero.");
    require(totalSupply() + _mintAmount <= maxSupply,"reached max supply");
    require(msg.value >= _mintAmount * publicSalePriceWei,"not enough money");
    _safeMint(_to,_mintAmount);
  }
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function toggleMintting() onlyOwner public{
    publicSaleStart = true;
  }
  function airdrop(address[] memory addressList,uint256[] memory countList) onlyOwner public{
    require(addressList.length == countList.length,"address length != count length");
    for (uint i=0; i<addressList.length; i++) {
      _safeMint(addressList[i],countList[i]);
    }
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}