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

contract IToddlerPillars {
	function balanceOf( address sender ) external view returns ( uint256 ) {}
}

contract CatharsisXToddlers is Delegated, ERC721Batch, PaymentSplitter {
  using Strings for uint;
  using Strings for uint8;
  using Strings for uint16;

  uint public MAX_SUPPLY = 444;
  uint[3] public PRICES = [
    0.070 ether,
    0.075 ether,
    0.080 ether
  ];

  bool public saleActive = false;
  IToddlerPillars public toddlerContract = IToddlerPillars(0xD6f817FA3823038D9a95B94cB7ad5468a19727FE);

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
    ERC721B("Catharsis X ToddlerPillars", "CXTP"){
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
  function mint( uint[3] calldata _tokenMint ) external payable {
    require( saleActive, "Sale is not active" );

    uint mintRequest = _tokenMint[0] + _tokenMint[1] + _tokenMint[2];
    require( mintRequest > 0, "Cannot mint 0 tokens" );
    require( totalSupply() + mintRequest <= MAX_SUPPLY,  "Mint would exceed supply" );

    uint toddlerBalance = toddlerContract.balanceOf(msg.sender);
    require( toddlerBalance > 0, "Must own Toddler Pillars" );
    require( _balances[ msg.sender ] + mintRequest <= toddlerBalance, "Mint exceeds allowance" );
    

    // check mint allowance
    if( toddlerBalance < 3 ) {
      // silver only
      require( _tokenMint[1] + _tokenMint[2] == 0, "Only silver allowed" );
    }
    else if( toddlerBalance < 6 ){
      require( _tokenMint[2] == 0, "Only silver or rose allowed" );
    }


    uint priceTotal = (
        ( PRICES[0] * _tokenMint[0] )
      + ( PRICES[1] * _tokenMint[1] )
      + ( PRICES[2] * _tokenMint[2] )
    );
    require( msg.value >= priceTotal, "Ether sent is not correct" );
    

    // handle token mints
    _balances[ msg.sender ] += mintRequest;
    for( uint t; t < 3; ++t ){
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
      uint totalQuantity;
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      require( totalSupply() + totalQuantity <= MAX_SUPPLY, "mint/order exceeds supply" );

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

  function setConfig(uint maxSupply, uint[3] calldata prices) external onlyDelegates {
    MAX_SUPPLY = maxSupply;
    PRICES = prices;
  }

  function setSaleState(bool _state) external onlyDelegates {
    saleActive = _state;
  }

  function setToddlerContract(address toddlerAddress) external onlyDelegates {
    if( address(toddlerContract) != toddlerAddress )
      toddlerContract = IToddlerPillars(toddlerAddress);
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