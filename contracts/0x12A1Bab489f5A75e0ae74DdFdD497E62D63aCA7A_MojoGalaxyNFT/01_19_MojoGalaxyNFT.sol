// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './Delegated.sol';
import './ERC721Batch.sol';
import './Signed.sol';

interface IERC20Withdraw{
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721Withdraw{
  function transferFrom(address from, address to, uint256 tokenId) external;
}
 

contract MojoGalaxyNFT is Delegated, ERC721Batch, Signed {
  using Strings for uint256;

  enum SaleState{
    NONE,
    PRESALE,
    MAINSALE
  }

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  MintConfig public config = MintConfig(
       0 ether, //ethPrice
       2,       //maxMint
       2,       //maxOrder
    5555,       //maxSupply

    SaleState.NONE
  );

  string public tokenURIPrefix;
  string public tokenURISuffix;

  constructor()
    ERC721B("Mojo Galaxy", "MG" )
    Signed( address(0) ){
  }


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }


  //payable
  function mint( uint quantity, bytes calldata signature ) external payable {
    MintConfig memory cfg = config;
    require( quantity > 0,             "must order 1+" );
    require( quantity <= cfg.maxOrder, "order too big" );
    require( owners[msg.sender].purchased + quantity <= cfg.maxMint, "mint limit reached" );
    require( totalSupply() + quantity <= cfg.maxSupply, "mint/order exceeds supply" );
    require( msg.value >= cfg.ethPrice * quantity, "ether sent is not correct" );

    if( cfg.saleState == SaleState.MAINSALE ){
      //no-op
    }
    else if( cfg.saleState == SaleState.PRESALE ){
      require( _signer != address(0), "Invalid signer" );
      require( _isAuthorizedSigner( abi.encodePacked(quantity), signature ),  "Account not authorized" );
    }
    else{
      revert( "sale is not active" );
    }

    owners[msg.sender].balance += uint8(quantity);
    owners[msg.sender].purchased += uint8(quantity);
    for(uint i; i < quantity; ++i){
      _mint( msg.sender );
    }
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      owners[ recipient[i] ].balance += uint8(quantity[i]);
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i] );
      }
    }
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    require( newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require( uint8(newConfig.saleState) < 3, "invalid sale state" );

    config = newConfig;
  }

  function setSigner( address signer ) external onlyDelegates {
    _setSigner(signer);
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }


  //withdraw
  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    Address.sendValue(payable(owner()), totalBalance);
  }

  function withdraw(address token) external onlyDelegates{
    IERC20Withdraw erc20 = IERC20Withdraw(token);
    erc20.transfer(owner(), erc20.balanceOf(address(this)) );
  }

  function withdraw(address token, uint256[] calldata tokenId) external onlyDelegates{
    for( uint256 i = 0; i < tokenId.length; ++i ){
      IERC721Withdraw(token).transferFrom(address(this), owner(), tokenId[i] );
    }
  }
}