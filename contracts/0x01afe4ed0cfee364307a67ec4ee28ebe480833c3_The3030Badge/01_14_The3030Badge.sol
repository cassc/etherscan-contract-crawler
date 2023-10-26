// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import './Blimpie/Delegated.sol';
import './Blimpie/Signed.sol';

contract The3030Badge is ERC1155, Delegated, Signed{
  struct Token{
    uint64 burnPrice;
    uint64 mintPrice;

    uint16 balance;
    uint16 supply;
    uint16 maxMint;

    bool isBurnActive;
    bool isMintActive;
    bool isMintAuthorized;

    string name;
    string uri;
  }

  string public name;
  string public symbol;
  Token[] public tokens;
  mapping(address => mapping(uint8 => uint16)) public claimed;

  constructor()
    Delegated()
    ERC1155("")
    Signed( 0xD81C3e92968D16bE26178c88c97F1a1C1a7311Cf ){
    name = "The 30/30 Badge";
    symbol = "30/30";

    setToken( 0, Token(
      1 ether,
      1 ether,
      
         0, //ignored
      9000,
         1,

      false,
      false,
      true,

      "The 30/30 Badge",
      ""
    ));
  }


  //external
  receive() external payable {}

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "no funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function exists(uint id) public view returns (bool) {
    return id < tokens.length;
  }

  function tokenSupply( uint id ) external view returns( uint ){
    require( exists( id ), "Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function totalSupply( uint id ) external view returns( uint ){
    require( exists( id ), "Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function uri( uint id ) public view override returns( string memory ){
    require( exists( id ), "Specified token (id) does not exist" );
    return tokens[id].uri;
  }


  //payable
  function mint( uint8 id, uint16 quantity, bytes calldata signature ) external payable {
    require( exists( id ), "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.isMintActive,                      "Sale is not active" );
    require( token.balance + quantity <= token.supply, "Not enough supply" );
    require( claimed[ msg.sender ][ id ] + quantity <= token.maxMint, "Already claimed" );
    require( msg.value >= token.mintPrice * quantity, "Ether sent is not correct" );

    if( token.isMintAuthorized )
      require( _isAuthorizedSigner( abi.encodePacked(quantity), signature ),  "Account not authorized" );


    token.balance += quantity;
    claimed[ msg.sender ][ id ] += quantity;
    _mint( msg.sender, id, quantity, "" );
  }


  //delegated
  function burnFrom( address account, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( ids.length == quantities.length, "Must provide equal ids and quantities");

    for(uint i; i < ids.length; ++i ){
      _burn( account, ids[i], quantities[i] );
    }
  }

  function mintTo( address[] calldata accounts, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( accounts.length == ids.length,   "Must provide equal accounts and ids" );
    require( ids.length == quantities.length, "Must provide equal ids and quantities");
    for(uint i; i < ids.length; ++i ){
      _mint( accounts[i], ids[i], quantities[i], "" );
    }
  }

  function setToken(uint id, Token memory token_ ) public onlyDelegates{
    require( id < tokens.length || id == tokens.length, "Invalid token id" );
    if( id == tokens.length )
      tokens.push();
    

    Token storage token = tokens[id];
    require( token.balance <= token_.supply, "Specified supply is lower than current balance" );


    token.burnPrice    = token_.burnPrice;
    token.mintPrice    = token_.mintPrice;

    //balance
    token.supply       = token_.supply;
    token.maxMint      = token_.maxMint;

    token.isBurnActive = token_.isBurnActive;
    token.isMintActive = token_.isMintActive;
    token.isMintAuthorized = token_.isMintAuthorized;

    token.name         = token_.name;
    token.uri          = token_.uri;

    if( bytes(token_.uri).length > 0 )
      emit URI( token_.uri, id );
  }

  function setSupply(uint id, uint16 supply) public onlyDelegates {
    require( exists( id ), "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance <= supply, "Specified supply is lower than current balance" );
    token.supply = supply;
  }

  function setURI(uint id, string calldata uri_) external onlyDelegates{
    require( exists( id ), "Specified token (id) does not exist" );
    tokens[id].uri = uri_;

    if( bytes( uri_ ).length > 0 )
      emit URI( uri_, id );
  }


  //onlyOwner
  function transferOwnership( address newOwner ) public override( Delegated, Ownable ) onlyOwner{
    Ownable.transferOwnership( newOwner );
  }
}