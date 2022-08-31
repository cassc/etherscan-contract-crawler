// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './Delegated.sol';
import './ERC721Batch.sol';
import './PaymentSplitterMod.sol';
import './Signed.sol';

interface IThe3030Badge{
  function balanceOf( address, uint ) external returns( uint );
  function burnFrom( address, uint[] calldata, uint[] calldata ) external payable;
}

contract MasterCats is Delegated, ERC721Batch, PaymentSplitterMod, Signed {
  using Strings for uint256;

  enum SaleState{
    NONE,   //0
    BADGE,  //1
    ALPHA,  //2
    _3,
    BETA,   //4
    _5,
    _6,
    _7,
    MAIN     //8
  }

  struct ClaimBalances{
    uint16 badge;
    uint16 alpha;
    uint16 beta;
    uint16 free;
  }

  struct MintConfig{
    uint64 ethPrice;
    uint16 freeMints;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    uint8  saleState;
    bool isFreeMintActive;
  }

  MintConfig public CONFIG = MintConfig(
    0.07 ether, //ethPrice
       1,       //freeMints
    9000,       //maxMint
      10,       //maxOrder
    9000,       //maxSupply

    uint8(SaleState.NONE), //saleState
    false
  );

  IThe3030Badge public PRINCIPAL = IThe3030Badge( 0x01aFE4Ed0CFee364307a67Ec4EE28ebe480833C3 );

  string public tokenURIPrefix;
  string public tokenURISuffix;

  constructor()
    ERC721B("Master Cats", "MASTER" )
    Signed( 0x41C9E80FAa5E12Ac1d61549267fB497041f0EFb8 ){

    _addPayee( 0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A, 32 ether );
    _addPayee( 0xf9467442d7f5c12283186101C80cd4a71497D7d5, 33 ether );
    _addPayee( 0x085FBF2d78308d2D69E9427d6D5eA774BCBC97AE, 15 ether );
    _addPayee( 0x4ba29e49F4EfeF6A4069e51545c31e4df634cdEA, 10 ether );
    _addPayee( 0x73b4c65d013c976cF774173FA3bd6f48Ec300419, 10 ether );
  }


  //view
  function getClaims( address account ) external returns( ClaimBalances memory balances ){
    require( address(PRINCIPAL) != address(0), "Invalid configuration" );

    MintConfig memory cfg = CONFIG;

    balances = ClaimBalances( 0, 0, 0, 0 );

    uint8 checkState = uint8(SaleState.BADGE);
    if( cfg.saleState & checkState == checkState ){
      balances.badge = uint16(PRINCIPAL.balanceOf( account, 0 ));
      if( balances.badge > owners[ account ].badges )
        balances.badge -= owners[ account ].badges;
      else
        balances.badge = 0;
    }

    checkState = uint8(SaleState.ALPHA);
    if( cfg.saleState & checkState == checkState )
      balances.alpha = uint16(PRINCIPAL.balanceOf( account, 1 ));

    checkState = uint8(SaleState.BETA);
    if( cfg.saleState & checkState == checkState )
      balances.beta = uint16(PRINCIPAL.balanceOf( account, 2 ));


    if( cfg.isFreeMintActive ){
      balances.free = CONFIG.freeMints;
      if( balances.free > owners[ account ].claimed )
        balances.free -= owners[ account ].claimed;
      else
        balances.free = 0;
    }

    return balances;
  }


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }


  function claim( uint16 badgeQty, uint16 alphaQty, uint16 betaQty, uint256[] calldata tokenIds, bytes calldata badgeSig ) external payable{
    MintConfig memory cfg = CONFIG;
    Owner memory prev = owners[msg.sender];
    if( badgeQty > 0 ){
      uint8 badgeState = uint8(SaleState.BADGE);
      require( cfg.saleState & badgeState == badgeState, "badge sale is disabled" );
      require( _isAuthorizedSigner( "1", badgeSig ), "not authorized for badge mints" );

      uint badgeBalance = PRINCIPAL.balanceOf( msg.sender, 0 );
      require( prev.badges + badgeQty <= badgeBalance, "all badges used" );
    }

    if( alphaQty > 0 ){
      uint8 alphaState = uint8(SaleState.ALPHA);
      require( cfg.saleState & alphaState == alphaState, "alpha sale is disabled" );
      PRINCIPAL.burnFrom( msg.sender, _asArray( 1 ), _asArray( alphaQty ) );
    }

    if( betaQty > 0 ){
      uint8 betaState = uint8(SaleState.BETA);
      require( cfg.saleState & betaState == betaState, "beta sale is disabled" );
      PRINCIPAL.burnFrom( msg.sender, _asArray( 2 ), _asArray( betaQty ) );
    }


    uint16 totalQuantity = badgeQty + alphaQty + betaQty;
    require( totalQuantity == tokenIds.length, "" );

    owners[msg.sender] = Owner(
      prev.balance + totalQuantity,
      prev.badges + badgeQty,
      prev.claimed,
      prev.purchased + totalQuantity
    );

    for(uint i; i < tokenIds.length; ++i){
      _mint( msg.sender, tokenIds[ i ] );
    }
  }

  //payable
  function mint( uint16 quantity ) external payable{
    MintConfig memory cfg = CONFIG;
    require( quantity > 0,                              "must order 1+" );
    require( quantity <= cfg.maxOrder,                  "order too big" );
    require( totalSupply() + quantity <= cfg.maxSupply, "mint/order exceeds supply" );

    uint8 mainState = uint8(SaleState.MAIN);
    require( cfg.saleState & mainState == mainState,    "sale is not active" );

    Owner memory prev = owners[msg.sender];
    require( prev.purchased + quantity <= cfg.maxMint,  "don't be greedy" );

    uint16 freeQty = 0;
    if( cfg.isFreeMintActive && cfg.freeMints > prev.claimed ){
      freeQty = cfg.freeMints - prev.claimed;
      if( quantity >= freeQty ){
        //use all free mints
        uint16 paidQty = quantity - freeQty;
        require( msg.value >= paidQty * cfg.ethPrice, "insufficient funds" );
      }
      else{
        freeQty = quantity;
      }
    }

    owners[msg.sender] = Owner(
      prev.balance + quantity,
      prev.badges,
      prev.claimed + freeQty,
      prev.purchased + quantity
    );

    for(uint i; i < quantity; ++i){
      _mint( msg.sender, _next() );
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
    require( supply + totalQuantity <= CONFIG.maxSupply, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], _next() );
      }
    }
  }

  function setConfig( MintConfig calldata config ) external onlyDelegates{
    CONFIG = config;
  }

  function setPrincipal( IThe3030Badge newPrincipal ) external onlyDelegates{
    PRINCIPAL = newPrincipal;
  }

  function setSigner( address newSigner ) external onlyDelegates{
    _setSigner( newSigner );
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

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee(index, account, newShares);
  }

  function _asArray(uint256 element) private pure returns (uint256[] memory array) {
    array = new uint256[](1);
    array[0] = element;
  }
}