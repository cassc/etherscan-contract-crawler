// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../Blimpie/Delegated.sol';
import '../IPowerPass1155.sol';
import './AM1155Base.sol';

interface IBalance {
  function balanceOf(address owner) external view returns(uint256);
}

abstract contract AMPowerPassCore is Delegated, AM1155Base, IPowerPass1155{
  struct Token {
    uint burnPrice;
    uint mintPrice;
    uint balance;
    uint supply;

    bool isBurnActive;
    bool isMintActive;

    string name;
    string uri;

    address[] payees;
    uint[] shares;
    uint totalShares;
  }

  IBalance public accessCollection;
  Token[] public tokens;

  //holds payee balances
  mapping(address => uint) public payouts;


  //safety first
  fallback() external payable {}

  receive() external payable {}


  //view
  function exists(uint id) public view returns( bool ){
    return id < tokens.length;
  }

  function tokenSupply( uint id ) external view returns( uint ){
    require(exists( id ), "ERC1155: Specified token (id) does not exist");
    return tokens[id].supply;
  }

  function totalSupply( uint id ) external view returns( uint ){
    require(exists( id ), "ERC1155: Specified token (id) does not exist");
    return tokens[id].supply;
  }

  function uri( uint id ) public view override returns( string memory ){
    require(exists( id ), "ERC1155: Specified token (id) does not exist");
    return tokens[id].uri;
  }


  //nonpayable
  function release(address account) external {
    require( payouts[ account ] > 0, "ERC1155: No balance due" );
    require( payouts[ account ] < address(this).balance, "ERC1155: Insufficent contract balance");

    uint balance = payouts[ account ];
    payouts[ account ] = 0;
    Address.sendValue(payable(account), balance);
  }


  //payable
  function mint( uint id, uint quantity ) public virtual payable{
    require(exists( id ), "ERC1155: Specified token (id) does not exist");

    Token storage token = tokens[id];
    require( token.isMintActive,                       "ERC1155: Sale is not active");
    require( token.balance + quantity <= token.supply, "ERC1155: Order exceeds supply");
    require( token.mintPrice * quantity <= msg.value,  "ERC1155: Ether sent is not correct");
    require( token.totalShares > 0,                    "ERC1155: Invalid token configuration, shares" );

    if( address(accessCollection) != address(0) )
      require( accessCollection.balanceOf( msg.sender ) > 0, "ERC1155: Access token balance is 0" );

    if( msg.value > 0 )
      _distrubuteValue( token );

    _mint( _msgSender(), id, quantity, "" );
  }


  //delegated
  function burnFrom( uint id, uint quantity, address account ) external payable onlyDelegates {
    require(exists( id ), "ERC1155: Specified token (id) does not exist");

    if( msg.value > 0 )
      _distrubuteValue( tokens[id] );

    _burn( account, id, quantity );
  }

  function mintTo( uint id, uint[] calldata quantities, address[] calldata accounts ) external payable onlyDelegates {
    require(exists(id), "ERC1155: Specified token (id) does not exist");
    require(quantities.length == accounts.length, "ERC1155: accounts and quantities length mismatch");

    if( msg.value > 0 )
      _distrubuteValue( tokens[id] );

    for(uint i; i < accounts.length; ++i ){
      _mint( accounts[i], id, quantities[i], "" );
    }
  }

  function setAccessCollection( IBalance collection ) public onlyDelegates {
    accessCollection = collection;
  }

  function setToken(uint id, string memory name_, string memory uri_,
    bool isBurnActive, uint burnPrice,
    bool isMintActive, uint mintPrice,
    uint supply ) public onlyDelegates{
    require( id < tokens.length || id == tokens.length, "ERC1155: Invalid token id" );
    if( id == tokens.length )
      tokens.push();


    Token storage token = tokens[id];
    token.burnPrice    = burnPrice;
    token.mintPrice    = mintPrice;
    token.supply       = supply;

    token.isBurnActive = isBurnActive;
    token.isMintActive = isMintActive;

    token.name         = name_;
    token.uri          = uri_;

    if( bytes(uri_).length > 0 )
      emit URI( uri_, id );
  }

  function setTokenPayouts( uint id, address[] memory payees, uint[] memory shares ) public onlyDelegates {
    require( id < tokens.length,             "ERC1155: Invalid token id" );
    require( payees.length > 0,              "ERC1155: Must provide 1+ payees" );
    require( payees.length == shares.length, "ERC1155: Must provide equal payees and shares" );
    tokens[id].payees = payees;
    tokens[id].shares = shares;

    uint total;
    for(uint i; i < shares.length; ++i ){
      require( payees[i] != address(0), "ERC1155: Payees cannot be empty" );
      require( shares[i] > 0,           "ERC1155: Shares cannot be empty" );
      total += shares[i];
    }
    tokens[id].totalShares = total;
  }

  function setSupply(uint id, uint supply) public onlyDelegates {
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance <= supply, "ERC1155: Specified supply is lower than current balance" );
    token.supply = supply;
  }

  function setURI(uint id, string calldata uri_) external onlyDelegates{
    require( exists( id ), "ERC1155: Specified token (id) does not exist" );
    tokens[id].uri = uri_;
    emit URI( uri_, id );
  }

  function _burn(address account, uint256 id, uint256 amount) private {
    require(exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance >= amount, "ERC1155: Not enough supply" );
    tokens[id].balance -= amount;
    tokens[id].supply -= amount;

    //START: base implementation
    uint256 accountBalance = _balances[id][account];
    require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
        _balances[id][account] = accountBalance - amount;
    }

    address operator = _msgSender();
    emit TransferSingle(operator, account, address(0), id, amount);
  }

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal {
    require(exists( id ), "ERC1155: Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.balance + amount <= token.supply, "ERC1155: Not enough supply" );
    token.balance += amount;

    //START: base implementation
    _balances[id][account] += amount;

    address operator = _msgSender();
    emit TransferSingle(operator, address(0), account, id, amount);
    _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
  }


  //private
  function _distrubuteValue( Token memory token ) internal{
    uint share;
    uint total;  
    for(uint i = 1; i < token.payees.length - 1; ++i ){
      share = msg.value * token.shares[i] / token.totalShares;
      payouts[ token.payees[i] ] += share;
      total += share;
    }

    //solidity will floor() the math, give remainder (majority) to first payee
    share = msg.value - total;
    payouts[ token.payees[0] ] += share;
  }
}