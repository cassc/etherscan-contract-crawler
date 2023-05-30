// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import './Blimpie/Delegated.sol';
import './Blimpie/ERC721Batch.sol';

contract DepressedApeRowClub is Delegated, ERC721Batch {
  using Strings for uint256;

  uint public MAX_MINT   = 25;
  uint public MAX_ORDER  = 25;
  uint public MAX_SUPPLY = 9900;
  uint public PRICE  = 0.012 ether;

  bool public isPresaleActive = false;
  bool public isMainsaleActive = false;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  constructor()
    ERC721B("Depressed Ape Row Club", "DARC", 0){
  }

  //safety first
  fallback() external payable {}

  receive() external payable {}

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "DARC: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function mint( uint quantity ) external payable {
    require( isMainsaleActive,                       "DARC: sale is not active" );
    require( 0 < quantity && quantity <= MAX_ORDER,  "DARC: order too big"             );
    require( msg.value >= PRICE * quantity,          "DARC: ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "DARC: mint/order exceeds supply" );

    owners[msg.sender].balance += uint16(quantity);
    owners[msg.sender].purchased += uint16(quantity);
    for( uint i; i < quantity; ++i ){
      _safeMint( msg.sender, supply++, "" );
    }
  }


  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "DARC: must provide equal quantities and recipients" );

    unchecked{
      uint totalQuantity;
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      uint supply = totalSupply();
      require( supply + totalQuantity <= MAX_SUPPLY, "DARC: mint/order exceeds supply" );

      for(uint i; i < recipient.length; ++i){
        if( quantity[i] > 0 ){
          owners[recipient[i]].balance += uint16(quantity[i]);
          for( uint j; j < quantity[i]; ++j ){
            _mint( recipient[i], supply++ );
          }
        }
      }
    }
  }

  function setActive(bool isPresaleActive_, bool isMainsaleActive_) external onlyDelegates{
    isPresaleActive = isPresaleActive_;
    isMainsaleActive = isMainsaleActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setConfig(uint maxOrder, uint maxSupply, uint maxMint, uint price) external onlyDelegates{
    require( maxSupply >= totalSupply(), "DARC: specified supply is lower than current balance" );
    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_MINT   = maxMint;
    PRICE      = price;
  }


  //private
  function _mint( address to, uint tokenId ) internal override {
    tokens.push( Token( to ) );
    emit Transfer( address(0), to, tokenId );
  }
}