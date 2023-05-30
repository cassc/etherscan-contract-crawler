// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/****************************************
 * @author: @hammm.eth                  *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721Batch.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

interface IMadRabbits {
	function balanceOf( address sender ) external view returns ( uint256 );
}

contract CatharsisXMadRabbits is Delegated, ERC721Batch, PaymentSplitter {
  using Strings for uint;
  using Strings for uint16;

  uint public MAX_SUPPLY = 555;
  uint public MAX_TX = 5;
  uint public PRICE = 0.07 ether;
  
  bool public salePaused = true;
  bool public publicSale = false;

  IMadRabbits public madRabbitsContract = IMadRabbits(0x57FBb364041D860995eD610579D70727AC51e470);

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

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
    ERC721B("Catharsis X MadRabbitsRiotClub", "CxMRRC", 0){
  }

  fallback() external payable {}

  function tokenURI( uint tokenId ) external view override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    return string(abi.encodePacked( _tokenURIPrefix, tokenId.toString(), _tokenURISuffix ));
  }

  function mint( uint quantity ) external payable {
    require( !salePaused, "Sale is not active" );
    require( quantity > 0 && quantity <= MAX_TX, "Invalid token quantity" );
    uint supply = totalSupply();
    require( supply + quantity < MAX_SUPPLY, "Quantity exceeds total supply" );

    if (publicSale == false) {
      uint madRabbitBalance = madRabbitsContract.balanceOf( msg.sender );
      require (madRabbitBalance > 0, "Must own a Mad Rabbits Riot Club to mint");
    }
    
    require( msg.value >= quantity * PRICE, "Ether sent is not correct" );
    
    for( uint i; i < quantity; ++i ){
      mint1( msg.sender );
    }
  }

  function mintTo( uint[] calldata quantity, address[] calldata recipient ) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint sum;
    for(uint i; i < quantity.length; ++i){
      sum += quantity[i];
    }
    require( totalSupply() + sum < MAX_SUPPLY, "Quantities exceed max supply");

    for(uint r; r < recipient.length; ++r){
      for(uint q; q < quantity[r]; ++q){
        mint1( recipient[r] );
      }
    }
  }

  function setBaseURI( string calldata _newPrefix, string calldata _newSuffix ) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setConfig( uint _maxSupply, uint _maxTx, uint _price ) external onlyDelegates {
    if( MAX_SUPPLY != _maxSupply ) {
      MAX_SUPPLY = _maxSupply;
    }
    
    if( MAX_TX != _maxTx ) {
      MAX_TX = _maxTx;
    }

    if( PRICE != _price ) {
      PRICE = _price;
    }
  }

  function toggleSalePaused () external onlyDelegates {
    salePaused = !salePaused;
  }

  function togglePublicSale () external onlyDelegates {
    publicSale = !publicSale;
  }

  function setMadRabbitsRiotClubContract( address _madRabbitsContract ) external onlyDelegates {
    if( address(madRabbitsContract) != _madRabbitsContract )
      madRabbitsContract = IMadRabbits(_madRabbitsContract);
  }

  //internal
  function mint1( address to ) internal {
    uint tokenId = _next();
    tokens.push(Token(to));

    _safeMint( to, tokenId, "" );
  }

  function _mint(address to, uint tokenId) internal override {
    emit Transfer(address(0), to, tokenId);
  }
}