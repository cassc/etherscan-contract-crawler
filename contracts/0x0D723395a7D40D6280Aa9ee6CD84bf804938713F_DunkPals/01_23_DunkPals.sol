// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './ERC721Batch.sol';
import './Merkle.sol';
import './PaymentSplitterMod.sol';
import './Royalties.sol';
import './Signed.sol';

interface IERC721Owner{
  function ownerOf( uint256 ) external view returns( address );
}

contract DunkPals is ERC721Batch, Merkle, PaymentSplitterMod, Royalties, Signed {
  using Strings for uint256;

  struct Allowance{
    address account;
    uint16 limit;
  }

  struct MintConfig{
    uint64 ethPrice;
    uint64 discPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    uint8 saleState;
  }

  enum SaleState{
    NONE,
    CLAIM,
    MAINSALE
  }

  MintConfig public config = MintConfig(
    0.042  ether, //ethPrice
    0.024  ether, //discPrice
       50,        //maxMint
       20,        //maxOrder
     4224,        //maxSupply

    uint8(SaleState.NONE)
  );

  IERC721Owner public poodleDunks = IERC721Owner( 0xdB9b851E8972bA0c179Bf8a9246A815411EF1CE4 );
  string public tokenURIPrefix;
  string public tokenURISuffix;

  uint256 public pineapples   = 1 ether / 400;
  uint256 public magicBurgers = 1 ether / 200;
  uint256 public regBurgers   = 1 ether / 100;
  uint256 public flush        = 1 ether /  20;

  mapping(uint256 => bool) nonces;

  constructor()
    ERC721B("DunkPals", "DNKP" )
    Royalties( owner(), 500, 10000 ) //5%
    Signed( 0x750142b3B633522b91dD801Dd6745AeE92D6A876 ){
  }


  //payable
  function claimRandom( uint256 random, bytes calldata signature, uint16 limit, bytes32[] calldata proof ) external {
    //OZ: checks
    MintConfig memory cfg = config;

    uint256 supply = totalSupply();
    require( supply < cfg.maxSupply, "mint/order exceeds supply" );
    require( !nonces[ random ],      "random used" );

    uint8 claimState = uint8(SaleState.CLAIM);
    require( cfg.saleState & claimState == claimState, "Claims are not active" );

    Owner memory prev = owners[msg.sender];

    //check the claim list
    bytes32 leaf = keccak256( abi.encode( Allowance( msg.sender, limit ) ) );
    require( _isValidProof( leaf, proof ), "not on the claim list" );
    require( prev.claimed < limit,         "all claims redeemed" );

    //verify the random
    require( _isAuthorizedSigner( abi.encodePacked(random), signature ),  "Invalid random" );

    //apply odds
    uint16 totalQuantity = _applyRandom( random );
    if( cfg.maxSupply < supply + totalQuantity ){
      totalQuantity = uint16(cfg.maxSupply - supply);
    }

    //OZ: effects
    nonces[ random ] = true;

    unchecked{
      owners[msg.sender] = Owner(
        prev.balance + totalQuantity,
        prev.claimed + 1,
        prev.purchased
      );

      //OZ: interactions
      for(uint256 i; i < totalQuantity; ++i){
        _mint( msg.sender );
      }
    }
  }


  //payable
  function mintRandom( uint256 random, int16 tokenId, bytes calldata signature ) external payable {
    //OZ: checks
    MintConfig memory cfg = config;

    uint256 supply = totalSupply();
    require( supply < cfg.maxSupply, "mint/order exceeds supply" );
    require( !nonces[ random ],      "random used" );

    Owner memory prev = owners[msg.sender];
    uint8 mainsale = uint8(SaleState.MAINSALE);
    if( cfg.saleState & mainsale == mainsale ){
      require( prev.purchased < cfg.maxMint, "don't be greedy" );

      if( tokenId > -1 && poodleDunks.ownerOf( uint256(uint16(tokenId)) ) == msg.sender )
        require( msg.value >= cfg.discPrice, "ether sent is not correct" );
      else
        require( msg.value >= cfg.ethPrice,  "ether sent is not correct" );
    }
    else{
      revert( "Sale is not active" );
    }


    require( _isAuthorizedSigner( abi.encodePacked(random), signature ),  "Invalid random" );
    uint16 totalQuantity = _applyRandom( random );
    if( cfg.maxSupply < supply + totalQuantity ){
      totalQuantity = uint16(cfg.maxSupply - supply);
    }

    //OZ: effects
    nonces[ random ] = true;

    unchecked{
      owners[msg.sender] = Owner(
        prev.balance + totalQuantity,
        prev.claimed,
        prev.purchased + 1
      );

      //OZ: interactions
      for(uint256 i; i < totalQuantity; ++i){
        _mint( msg.sender );
      }
    }
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    unchecked{
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    require( totalSupply() + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );

    unchecked{
      for(uint256 i; i < recipient.length; ++i){
        owners[recipient[i]].balance += quantity[i];
        for(uint256 j; j < quantity[i]; ++j){
          _mint( recipient[i] );
        }
      }
    }
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    require( newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require( uint8(newConfig.saleState) < 4, "invalid sale state" );

    config = newConfig;
  }

  function setOdds( uint256 pineappleOdds, uint256 magicBurgerOdds, uint256 regBurgerOdds, uint256 flushOdds ) external onlyDelegates{
    pineapples   = pineappleOdds;
    magicBurgers = magicBurgerOdds;
    regBurgers   = regBurgerOdds;
    flush        = flushOdds;
  }

  function setPoodleDunks( IERC721Owner pdAddress ) external onlyDelegates{
    poodleDunks = pdAddress;
  }

  function setSigner( address signer ) external onlyDelegates{
    _setSigner( signer );
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }


  //onlyOwner
  function addPayee(address account, uint256 shares_) external onlyOwner {
    _addPayee( account, shares_ );
  }

  function resetCounters() external onlyOwner {
    _resetCounters();
  }

  function setDefaultRoyalty( address receiver, uint16 feeNumerator, uint16 feeDenominator ) public onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee(index, account, newShares);
  }


  //view: IERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableB, Royalties) returns (bool) {
    return ERC721EnumerableB.supportsInterface(interfaceId)
      || Royalties.supportsInterface(interfaceId);
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) external view returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);



    //DunkPals Treasury 35%
    //Pineapple 35%
    //Squeebo 15%
    //Earlybail 10%
    //Danny 5% 
  }


  function _applyRandom( uint256 random ) internal view returns( uint16 ){
    if( random < pineapples )
      return 6;

    if( random < magicBurgers )
      return 4;
    
    if( random < regBurgers )
      return 3;

    if( random < flush )
      return 2;

    return 1;
  }
}