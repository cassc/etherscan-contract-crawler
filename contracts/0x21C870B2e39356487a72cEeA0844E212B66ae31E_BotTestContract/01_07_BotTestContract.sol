// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BotTestContract is ERC721A, Ownable {

  using Strings for uint256;
  string _baseTokenURI;
  uint256 public MAX_SUPPLY = 500;


  constructor(string memory baseURI) ERC721A("BotTestContract", "BTC") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }


  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    _safeMint(msg.sender, _count);
    
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
    require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
      string memory currentBaseURI = _baseURI();
    return bytes( currentBaseURI ).length > 0 ? string( abi.encodePacked( currentBaseURI, _tokenId.toString(), ".json" ) ) : "";
  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }

}