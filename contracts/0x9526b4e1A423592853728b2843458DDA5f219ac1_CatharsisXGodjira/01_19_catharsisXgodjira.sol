// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************************
 * @author: @Danny_One_                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Delegated.sol';
import './ERC721Batch.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

interface IGodjira {
	function balanceOf( address sender ) external view returns ( uint256 );
}

contract CatharsisXGodjira is Delegated, ERC721Batch, PaymentSplitter {
  using Strings for uint;
  using Strings for uint16;

  uint public MAX_SUPPLY = 999;
  uint public MAX_GOLD = 333;
  uint public MAX_PRESALE = 1;
  uint public MAX_TX = 10;

  uint[2] public PRICES = [
    0.1 ether,
    0.1 ether
  ];
  
  enum SaleState {
    paused,
    genesis,
    second,
    publicSale
  }

  SaleState public saleState;
  IGodjira public godjiraGenesis = IGodjira(0x9ada21A8bc6c33B49a089CFC1c24545d2a27cD81);
  IGodjira public godjiraExpansion = IGodjira(0xEDc3AD89f7b0963fe23D714B34185713706B815b);

  mapping(TOKEN_TYPE => uint16) public typeBalance;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;
  string private _tokenURISeparator;

  address[] private payees = [
    0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A,
    0x172c418b3bDA2Ad1226287376051f5749567d568
  ];

  uint[] private splits = [
    10,
    90
  ];

  constructor()
    Delegated()
    PaymentSplitter( payees, splits )
    ERC721B("Catharsis X Godjira", "CXGJ"){
  }

  //external payable
  fallback() external payable {}

  //public view
  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix,
      tokenId.toString(), _tokenURISeparator,
      uint(tokens[tokenId].tokenType).toString(), _tokenURISeparator,
      tokens[tokenId].typeIndex.toString(),
      _tokenURISuffix ));
  }

  function typeSold( TOKEN_TYPE type_ ) external view returns( uint count ){
    for(uint i; i < tokens.length; ++i ){
      if( tokens[i].tokenType == type_ )
        ++count;
    }
  }

  //public payable
  function mint( uint[2] calldata _tokenMint ) external payable {
    require( saleState > SaleState.paused, "Sale is not active" );

    uint mintRequest = _tokenMint[0] + _tokenMint[1];
    require( mintRequest > 0, "Cannot mint 0 tokens" );
    require( typeBalance[TOKEN_TYPE.GOLD] + _tokenMint[1] <= MAX_GOLD, "Gold supply exceeded" );
    require( typeBalance[TOKEN_TYPE.SILVER] + _tokenMint[0] <= MAX_SUPPLY - MAX_GOLD, "Silver supply exceeded" );

    uint godjiraBalance = godjiraGenesis.balanceOf(msg.sender);
    if( saleState == SaleState.genesis ) {
      require( godjiraBalance > 0, "Must own Genesis Godjira" );
      require( _balances[ msg.sender ] + mintRequest <= MAX_PRESALE, "Mint exceeds presale allowance" );
    }
    else if( saleState < SaleState.publicSale ) {
      godjiraBalance += godjiraExpansion.balanceOf(msg.sender);
      require( godjiraBalance > 0, "Must own a Godjira" );
      require( _balances[ msg.sender ] + mintRequest <= MAX_PRESALE, "Mint exceeds presale allowance" );
    }
    else {
      require( mintRequest <= MAX_TX, "Mint exceeds transaction limit" );
    }
	
    uint priceTotal = (
        ( PRICES[0] * _tokenMint[0] )
      + ( PRICES[1] * _tokenMint[1] )
    );
    require( msg.value >= priceTotal, "Ether sent is not correct" );
    
    // handle token mints
    _balances[ msg.sender ] += mintRequest;
    for( uint t; t < 2; ++t ){
      for(uint tq; tq < _tokenMint[t]; ++tq ){
        mint1(msg.sender, TOKEN_TYPE(t) );
      }
    }
  }



  //onlyDelegates
  function mintTo(TOKEN_TYPE[] calldata types, uint[] calldata quantity, address[] calldata recipient ) external payable onlyDelegates{
    require(types.length == quantity.length, "must provide equal types and quantities" );
    require(quantity.length == recipient.length, "must provide equal quantities and recipients" );

    unchecked{
      uint[2] memory totalQuantity;
      for(uint i; i < quantity.length; ++i){
        if( types[i] == TOKEN_TYPE.SILVER ) {
          totalQuantity[0] += quantity[i];
        } else if( types[i] == TOKEN_TYPE.GOLD ) {
          totalQuantity[1] += quantity[i];
        }
      }
      require( typeBalance[TOKEN_TYPE.GOLD] + totalQuantity[1] <= MAX_GOLD, "Gold supply exceeded" );
      require( typeBalance[TOKEN_TYPE.SILVER] + totalQuantity[0] <= MAX_SUPPLY - MAX_GOLD, "Silver supply exceeded" );

      for(uint r; r < recipient.length; ++r){
        _balances[ recipient[r] ] += quantity[r];
        for(uint q; q < quantity[r]; ++q){
          mint1( recipient[r], types[r] );
        }
      }
    }
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix, string calldata _newSeparator) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
    _tokenURISeparator = _newSeparator;
  }

  function setConfig(uint maxSupply, uint maxGold, uint maxPresale, uint maxTx, uint[2] calldata prices) external onlyDelegates {
    if( MAX_SUPPLY != maxSupply ) {
      MAX_SUPPLY = maxSupply;
    }
    if( MAX_GOLD != maxGold ) {
      MAX_GOLD = maxGold;
    }
    if( MAX_PRESALE != maxPresale ) {
      MAX_PRESALE = maxPresale;
    }
    if( MAX_TX != maxTx ) {
      MAX_TX = maxTx;
    }
    if( PRICES.length == prices.length ) {
      for( uint i=0; i < prices.length; i++ ) {
        if( PRICES[i] != prices[i] ) {
          PRICES[i] = prices[i];
        }
      }
    }
  }

  function setSaleState(SaleState _state) external onlyDelegates {
    saleState = _state;
  }

  function setGodjiraContract(address _godjiraGenesis, address _godjiraExpansion) external onlyDelegates {
    if( address(godjiraGenesis) != _godjiraGenesis )
      godjiraGenesis = IGodjira(_godjiraGenesis);
    if( address(godjiraExpansion) != _godjiraExpansion )
      godjiraExpansion = IGodjira(_godjiraExpansion);
  }


  //internal
  function mint1( address to, TOKEN_TYPE tokenType ) internal {
    uint16 typeIndex = typeBalance[ tokenType ]++;
    uint tokenId = _next();
    tokens.push(Token(
      to,
      typeIndex,
      tokenType
    ));

    _safeMint( to, tokenId, "" );
  }

  function _mint(address to, uint tokenId) internal override {
    emit Transfer(address(0), to, tokenId);
  }
}