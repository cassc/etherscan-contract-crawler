// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/****************************************
 * @author: @hammm.eth                  *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Blimpie/Delegated.sol';
import './Blimpie/PaymentSplitterMod.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

interface ICyberHornets {
	function balanceOf( address account ) external view returns (uint256);
}

contract CyberHornetsComic is Delegated, ERC1155, PaymentSplitterMod {
  uint public MAX_SUPPLY = 3000;

  uint public PRESALE_PRICE = 0 ether;
  uint public PRESALE_MAX_TX = 1;
  mapping( address => bool ) public presaleClaimed;

  uint public PUBLIC_MAX_TX = 4;
  uint public PUBLIC_PRICE = 0.02 ether;

  string public name = "Cyber Hornets: Comics";
  string public symbol = "CH:C";
  
  struct Token{
    string name;
    string uri;
    uint16 balance;
    uint16 supply;
  }

  Token[] public tokens;

  enum SaleState {
    paused,
    presale,
    publicSale
  }

  SaleState public saleState;

  ICyberHornets public CyberHornetsColonyClubProxy = ICyberHornets(0x821043B51Bd384f2CaA0d09dc136181870B2beA2);
  ICyberHornets public CyberHornetsAnimusProxy = ICyberHornets(0x6c37F6cfE665c22B8a407430651e9EE31d71D1cf);

  constructor()
    Delegated()
    ERC1155( "" ){
    _addPayee(0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A, 11);
    _addPayee(0x01c7812a88b221766C445fb5dBDE43C95d5c6494, 89);

    tokens.push(Token("Cover 1", "https://cyberhornetscolony.com/digital-comic/metadata/0.json", 0, 1000));
    tokens.push(Token("Cover 2", "https://cyberhornetscolony.com/digital-comic/metadata/1.json", 0, 1000));
    tokens.push(Token("Cover 3", "https://cyberhornetscolony.com/digital-comic/metadata/2.json", 0, 1000));
  }

  function exists(uint id) external view returns (bool) {
    return id < tokens.length;
  }

  function tokenSupply( uint id ) external view returns( uint ){
    require(id < tokens.length, "Specified token (id) does not exist" );
    return tokens[id].balance;
  }

  function totalSupply () public view returns ( uint ){
    uint sum;
    for( uint i; i < tokens.length; ++i ) {
      sum += tokens[i].balance;
    }
    return sum;
  }

  function uri( uint id ) public override view returns ( string memory ){
    require(id < tokens.length, "Specified token (id) does not exist" );
    return tokens[id].uri;
  }


  function mint( uint quantity ) external payable{
    require( saleState > SaleState.paused, "Sale is not active" );
    require( totalSupply() + quantity <= MAX_SUPPLY, "Cannot exceed max supply" );

    if( saleState == SaleState.presale ){
      require( msg.value >= PRESALE_PRICE * quantity,  "Ether sent is not correct" );
      require( presaleClaimed[msg.sender] != true, "Only one comic per account" );
      if( address(CyberHornetsColonyClubProxy) == address(0)
        || address(CyberHornetsAnimusProxy) == address(0) ){
        revert( "Invalid proxy configuraiton" );
      }

      if( CyberHornetsColonyClubProxy.balanceOf( msg.sender ) > 0
        || CyberHornetsAnimusProxy.balanceOf( msg.sender ) > 0 ){
        
        presaleClaimed[msg.sender] = true;
        uint id = randomMintId();
        ++tokens[id].balance;
        _mint( msg.sender, id, 1, "" );
      }
      else{
        revert( "Must own a CHCC or CH Animus to claim during presale" );
      }
    }
    else if ( saleState == SaleState.publicSale ){
      require( msg.value >= PUBLIC_PRICE * quantity,  "Ether sent is not correct" );
      require( quantity <= PUBLIC_MAX_TX && quantity > 0, "Invalid quantity");

      uint id;
      for( uint i; i < quantity; ++i ) {
        id = randomMintId();
        ++tokens[id].balance;
        _mint( msg.sender, id, 1, "" );
      }
    }
  }

  function mintTo( address[] calldata accounts, uint[] calldata quantities ) external payable onlyDelegates {
    require( accounts.length == quantities.length, "Must provide equal accounts and quantities");

    uint sum;
    for(uint k; k < quantities.length; ++k ){
      sum += quantities[k];
    }
    require( totalSupply() + sum <= MAX_SUPPLY, "Cannot exceed max supply");
 
    uint id;
    for(uint i; i < quantities.length; ++i ){
      for( uint j; j < quantities[i]; ++j ) {
        id = randomMintId();
        ++tokens[id].balance;
        _mint( accounts[i], id, 1, "" );
      }
    }
  }

  function randomMintId() internal view returns ( uint ) {
    uint currentId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, totalSupply()))) % tokens.length;
    for( uint i; i < tokens.length;  ++i ){
      currentId = currentId + i % tokens.length;
      if (tokens[currentId].balance < tokens[currentId].supply)
        return currentId;
    }

    revert( "No available supply" );
  }

  function setToken(uint id, uint16 supply_, string calldata uri_ ) public onlyDelegates{
    require( id < tokens.length || id == tokens.length, "Invalid token id" );

    if( id == tokens.length ){
      tokens.push();
    }

    Token storage token = tokens[id];
    token.uri = uri_;

    require( supply_ >= token.balance, "Supply is lower than balance" );
    token.supply = supply_;
  }

  function setPrice ( uint _presalePrice, uint _publicPrice ) external onlyDelegates {
    PRESALE_PRICE = _presalePrice;
    PUBLIC_PRICE = _publicPrice;
  }

  function setCHCCContract( address _cyberHornetsColonyClubProxy ) external onlyDelegates {
    require( address(CyberHornetsColonyClubProxy) != _cyberHornetsColonyClubProxy );
    CyberHornetsColonyClubProxy = ICyberHornets(_cyberHornetsColonyClubProxy);
  }

  function setCHAnimusContract( address _cyberHornetsAnimusProxy ) external onlyDelegates {
    require( address(CyberHornetsAnimusProxy) != _cyberHornetsAnimusProxy );
    CyberHornetsAnimusProxy = ICyberHornets(_cyberHornetsAnimusProxy);
  }

  function setMaxSupply ( uint _newMaxSupply ) external onlyDelegates { 
    require( totalSupply() <= _newMaxSupply, "New supply must meet or exceed current supply");
    MAX_SUPPLY = _newMaxSupply;
  }

  function setSaleState(SaleState _state) external onlyDelegates {
    saleState = _state;
  }
}