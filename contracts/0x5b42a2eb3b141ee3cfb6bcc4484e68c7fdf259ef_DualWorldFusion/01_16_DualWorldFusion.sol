// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX.eth                 *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Blimpie/Delegated.sol';
import './Blimpie/ERC721EnumerableB.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract DualWorldFusion is Delegated, ERC721EnumerableB, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 1400;
  uint public PRICE      = 0.25 ether;

  bool public isActive   = false;
  uint public maxOrder   = 20;

  uint private _supply = 1401;
  string private _baseTokenURI = 'https://us-central1-dual-world-fusion.cloudfunctions.net/app/nft/';
  string private _tokenURISuffix = '';

  address[] private payees = [
    0x91aecdAf903e750A8f89b3aae38552395392DEA2,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  uint[] private splits = [
    95,
     5
  ];

  constructor()
    ERC721B("Dual World Fusion", "DWF")
    PaymentSplitter( payees, splits ){
    _owners.push(address(0));
  }

  //external

  fallback() external payable {}

  function mintNFT( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRICE * quantity, "Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= _supply, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }


  //owner
  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= _supply, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setMaxOrder(uint maxOrder_) external onlyDelegates{
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder_;
  }

  function setPrice(uint price ) external onlyDelegates{
    require( PRICE != price, "New value matches old" );
    PRICE = price;
  }

  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates{
    _baseTokenURI = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require(MAX_SUPPLY != maxSupply, "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
    _supply = maxSupply + 1;
  }

  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }
}