// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './Delegated.sol';
import './ERC721Batch.sol';
import './Merkle.sol';
import './Royalties.sol';



interface IERC20Withdraw{
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721Withdraw{
  function transferFrom(address from, address to, uint256 tokenId) external;
}
 
contract HashCats is Delegated, ERC721Batch, Royalties, Merkle {
  using Address for address;
  using Strings for uint256;

  enum SaleState{
    NONE,
    PRESALE,
    MAINSALE
  }

  struct MintConfig{
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    uint8 saleState;
  }

  struct PriceCurve{
    uint16 mark;
    uint256 price;
  }

  MintConfig public config = MintConfig(
       20,       //maxMint
       20,       //maxOrder
    10000,       //maxSupply

    uint8(SaleState.NONE)
  );

  address public withdrawTo = 0x49bdF5aFDF2dfF8a0890c7A37fEc90c3ae816187;
  PriceCurve[] public pricing;

  string public tokenURIPrefix = "https://www.hashcats.io/metadata/prereveal.json?";
  string public finalURIPrefix = "";
  string public tokenURISuffix = "";

  constructor()
    ERC721B("HashCats", "HC" )
    Royalties( address(this), 500, 10000 ){

    pricing.push( PriceCurve(     5, 0.030 ether ) );
    pricing.push( PriceCurve(    10, 0.025 ether ) );
    pricing.push( PriceCurve( 10000, 0.020 ether ) );
  }


  //safety first
  receive() external payable {}


  //payable
  function mint( uint16 quantity, bytes32[] calldata proof ) external payable {
    MintConfig memory cfg = config;
    uint16 ownerBalance = owners[ msg.sender ].balance;

    require( quantity > 0,                              "Must order 1+" );
    require( quantity <= cfg.maxOrder,                  "Order too big" );
    require( ownerBalance + quantity <= cfg.maxMint,    "Wallet limit reached" );
    require( totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply" );

    uint256 totalPrice = calculateTotal( msg.sender, quantity );
    require( msg.value == totalPrice, "Ether sent is not correct" );


    if( cfg.saleState == uint8(SaleState.MAINSALE) ){
      //no-op
    }
    else if( cfg.saleState == uint8(SaleState.PRESALE) ){
      require( _isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof ), "You are not on the access list" );
    }
    else{
      revert( "Sale is not active" );
    }

    owners[ msg.sender ].balance += quantity;
    owners[ msg.sender ].purchased += quantity;
    for( uint256 i = 0; i < quantity; ++i ){
      _mint(Token( msg.sender, 9 ));
    }
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint256 totalQuantity;
    uint256 supply = totalSupply();
    for(uint256 i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );


    for(uint256 i; i < recipient.length; ++i){
      owners[ recipient[i] ].balance += quantity[i];
      for(uint256 j; j < quantity[i]; ++j){
        Token memory token = Token( recipient[i], 9 );
        _mint( token );
      }
    }
  }

  function burnFrom( address account, uint16[] calldata tokenIds ) external onlyDelegates{
    owners[ account ].balance -= uint16(tokenIds.length);
    for(uint i; i < tokenIds.length; ++i ){
      _burn( account, tokenIds[i] );
    }
  }

  function setConfig( MintConfig calldata config_ ) external onlyDelegates{
    require( config_.maxOrder <= config_.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= config_.maxSupply, "max supply must be gte total supply" );

    config = config_;
  }

  function setPricingCurve( uint16[] calldata marks, uint256[] calldata newPrices ) external onlyDelegates {
    require( marks.length == newPrices.length, "must provide equal marks and prices" );

    while( marks.length > pricing.length ){
      pricing.pop();
    }

    uint16 prevMark = 0;
    for( uint256 i = 0; i < marks.length; ++i ){
      require( i > 0 && marks[i] > prevMark, "quantity marks must increase" );
      prevMark = marks[i];

      if( i == pricing.length )
        pricing.push();

      pricing[ i ] = PriceCurve( prevMark, newPrices[i] );
    }
  }

  function setTokenURI( string calldata prefix, string calldata finalPrefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    finalURIPrefix = finalPrefix;

    tokenURISuffix = suffix;
  }

  //onlyOwner
  function setDefaultRoyalty( address receiver, uint16 royaltyNum, uint16 royaltyDenom ) external onlyOwner {
    _setDefaultRoyalty( receiver, royaltyNum, royaltyDenom );
  }

  function setWithdrawTo( address newRecipient ) external {
    withdrawTo = newRecipient;
  }


  //withdraw
  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    Address.sendValue(payable(withdrawTo), totalBalance);
  }

  function withdraw(address token) external {
    IERC20Withdraw erc20 = IERC20Withdraw(token);
    erc20.transfer( withdrawTo, erc20.balanceOf(address(this)) );
  }

  function withdraw(address token, uint256[] calldata tokenId) external {
    for( uint256 i = 0; i < tokenId.length; ++i ){
      IERC721Withdraw(token).transferFrom( address(this), withdrawTo, tokenId[i] );
    }
  }


  //view
  function calculateTotal( address account, uint16 quantity ) public view returns( uint256 totalPrice ){
    uint256 p = 0;
    uint16 ownerBalance = owners[ account ].balance;
    for( uint256 i = 0; i < quantity; ++i ){
      for( ; p < pricing.length; ++p ){
        if(( ownerBalance + 1 + i ) < pricing[ p ].mark ){
          totalPrice += pricing[ p ].price;
          break;
        }
      }
    }
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) public view override returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");

    Token memory token = tokens[ tokenId ];
    if( token.lives > 0 ){
      return bytes(tokenURIPrefix).length > 0 ?
        string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix)):
        "";
    }
    else{
      return bytes(finalURIPrefix).length > 0 ?
        string(abi.encodePacked(finalURIPrefix, tokenId.toString(), tokenURISuffix)):
        "";
    }
  }



  //view: IERC165
  function supportsInterface( bytes4 interfaceId ) public view override( ERC721EnumerableB, Royalties ) returns( bool ){
    return ERC721EnumerableB.supportsInterface( interfaceId )
      || Royalties.supportsInterface( interfaceId );
  }


  //internal
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    Token storage token = tokens[ tokenId ];
    if( token.lives > 0 ){
      if( from != address(0) && to != address(0) )
        --token.lives;
    }

    super._beforeTokenTransfer( from, to, tokenId );
  }
}