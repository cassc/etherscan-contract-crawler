// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Blimpie/Delegated.sol';
import './Blimpie/ERC721EnumerableLite.sol';
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Roboiz is Delegated, ERC721EnumerableLite, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 4500;
  uint public MAX_SUPPLY = 4500;
  uint public PRICE      = 0.06 ether;

  bool public isActive   = false;

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '';

  address[] private payees = [
    0x2B6031Cf84A48041Cf1fF9FD8D8403f612242948,
    0x1A4d5A7F00E2f07D444756C956E8b08EAc59C5d8,
    0xfbB123Cf6F09dB46Bb11D590F1A6a417aA1918c1
  ];
  uint[] private splits = [
    325,
    325,
    350
  ];

  constructor()
    Delegated()
    ERC721B("Roboiz", "BOIZ")
    PaymentSplitter( payees, splits ){
  }

  //external
  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRICE * quantity, "Ether sent is not correct" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i = 0; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }


  //delegated
  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    uint256 supply = totalSupply();
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i = 0; i < recipient.length; ++i){
      for(uint j = 0; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setMaxOrder(uint maxOrder) external onlyDelegates{
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder;
  }

  function setPrice(uint price ) external onlyDelegates{
    require( PRICE != price, "New value matches old" );
    PRICE = price;
  }

  function setBaseURI(string calldata newBaseURI, string calldata newSuffix) external onlyDelegates{
    _baseTokenURI = newBaseURI;
    _tokenURISuffix = newSuffix;
  }

  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require( MAX_SUPPLY != maxSupply, "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }
}