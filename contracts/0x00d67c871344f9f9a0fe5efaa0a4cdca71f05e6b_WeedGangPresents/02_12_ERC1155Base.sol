// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 ****************************************/

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import './Delegated.sol';

contract ERC1155Base is Delegated, ERC1155 {
  struct Token{
    uint burnPrice;
    uint mintPrice;
    uint balance;
    uint supply;

    bool isBurnActive;
    bool isMintActive;

    string name;
    string uri;

    //mapping(string => string) metadata;
  }

  string public name;
  string public symbol;
  Token[] public tokens;

  constructor( string memory name_, string memory symbol_ )
    Delegated()
    ERC1155(""){
    name = name_;
    symbol = symbol_;
  }


  //external
  receive() external payable {}

  function exists(uint id) public view returns (bool) {
    return id < tokens.length;
  }

  function tokenSupply( uint id ) external view returns( uint ){
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function totalSupply( uint id ) external view returns( uint ){
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function uri( uint id ) public view override returns( string memory ){
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    return tokens[id].uri;
  }


  //payable
  function burn( uint id, uint quantity ) external payable{
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.isBurnActive,                      "ERC1155: Sale is not active"        );
    require( msg.value >= token.burnPrice * quantity, "ERC1155: Ether sent is not correct" );
    _burn( _msgSender(), id, quantity );
  }

  function mint( uint id, uint quantity ) external virtual payable{
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.isMintActive,                      "ERC1155: Sale is not active"        );
    require( msg.value >= token.mintPrice * quantity, "ERC1155: Ether sent is not correct" );
    _mint( _msgSender(), id, quantity, "" );
  }


  //delegated
  function burnFrom( address account, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( ids.length == quantities.length, "ERC1155: Must provide equal ids and quantities");

    for(uint i; i < ids.length; ++i ){
      _burn( account, ids[i], quantities[i] );
    }
  }

  function mintTo( address[] calldata accounts, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( accounts.length == ids.length,   "ERC1155: Must provide equal accounts and ids" );
    require( ids.length == quantities.length, "ERC1155: Must provide equal ids and quantities");
    for(uint i; i < ids.length; ++i ){
      _mint( accounts[i], ids[i], quantities[i], "" );
    }
  }

  function setToken(uint id, string memory name_, string memory uri_, uint supply,
    bool isBurnActive, uint burnPrice,
    bool isMintActive, uint mintPrice ) public onlyDelegates{
    require( id < tokens.length || id == tokens.length, "ERC1155: Invalid token id" );
    if( id == tokens.length )
      tokens.push();


    Token storage token = tokens[id];
    token.name         = name_;
    token.uri          = uri_;
    token.isBurnActive = isBurnActive;
    token.isMintActive = isMintActive;
    token.burnPrice    = burnPrice;
    token.mintPrice    = mintPrice;
    token.supply       = supply;

    if( bytes(uri_).length > 0 )
      emit URI( uri_, id );
  }

  /*
  function setMetadata(uint id, string[] calldata keys, string[] calldata values ) external onlyDelegates{
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    require( keys.length == values.length, "ERC1155: Must provide equal keys and values" );
    Token storage token = tokens[id];
    for( uint i; i < keys.length; ++i ){
      token.metadata[ keys[i] ] = values[i];
    }
  }
  */

  function setSupply(uint id, uint supply) public onlyDelegates {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.supply != supply,  "ERC1155: New value matches old" );
    require( token.balance <= supply, "ERC1155: Specified supply is lower than current balance" );
    token.supply = supply;
  }

  function setURI(uint id, string calldata uri_) external onlyDelegates{
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    tokens[id].uri = uri_;
    emit URI( uri_, id );
  }


  //internal
  function _burn(address account, uint256 id, uint256 amount) internal virtual override {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance >= amount, "ERC1155: Not enough supply" );

    tokens[id].balance -= amount;
    tokens[id].supply -= amount;
    super._burn( account, id, amount );
  }

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance + amount <= token.supply, "ERC1155: Not enough supply" );

    token.balance += amount;
    super._mint( account, id, amount, data );
  }
}