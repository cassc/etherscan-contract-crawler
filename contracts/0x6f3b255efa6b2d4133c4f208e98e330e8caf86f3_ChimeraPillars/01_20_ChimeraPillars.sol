// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './Blimpie/Delegated.sol';
import './Blimpie/ERC721Batch.sol';
import './Blimpie/PaymentSplitterMod.sol';
import './Blimpie/SignedSecret.sol';

interface IToddlerPillars{
  function balanceOf( address account ) external returns( uint );
}

contract ChimeraPillars is Delegated, ERC721Batch, PaymentSplitterMod, SignedSecret {
  using Strings for uint256;

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    bool   isClaimActive;
    bool   isPresaleActive;
    bool   isMainsaleActive;
  }

  MintConfig public CONFIG = MintConfig(
    0.03 ether, //ethPrice
       4,       //maxMint
       4,       //maxOrder
    8888,       //maxSupply

    false,      //isClaimActive
    false,      //isPresaleActive
    false       //isMainsaleActive
  );

  IToddlerPillars public ToddlerPillars = IToddlerPillars(0xD6f817FA3823038D9a95B94cB7ad5468a19727FE);

  string public tokenURIPrefix;
  string public tokenURISuffix;

  constructor()
    ERC721B("Chimera Pillars", "CMPL", 0)
    SignedSecret( 0x07743F7CCE5893a00125cea50145CB394A58dfFe, "LionGoatSnakeTail" ){

    _addPayee( 0x422D9914eE2A933a040815F9A619D27252373EbD, 87 ether );
    _addPayee( 0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A, 13 ether );
  }


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }


  function claim( uint8 quantity, bytes calldata signature ) external payable {
    require( CONFIG.isClaimActive, "claim is not active" );
    require( 0 < quantity && quantity <= 2, "must claim 1 or 2" );

    uint supply = totalSupply();
    require( supply + quantity <= CONFIG.maxSupply, "claim exceeds supply" );

    uint balance = ToddlerPillars.balanceOf( msg.sender );
    if( balance > 0 ){
      //2 allowed
      if( balance > 8 )
        require( owners[msg.sender].claimed + quantity <= 2, "only 2 ChimeraPillars may be claimed" );

      //1 allowed
      else
        require( owners[msg.sender].claimed + quantity == 1, "only 1 ChimeraPillar may be claimed" );
    }
    else{
      revert( "must own ToddlerPillars" );
    }

    require( _isAuthorizedSigner( uint(quantity).toString(), signature ),  "account not authorized" );

    owners[msg.sender].balance += quantity;
    owners[msg.sender].claimed += quantity;
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, tokens.length );
    }
  }


  //payable
  function mint( uint8 quantity ) external payable {
    require( quantity > 0,                      "must order 1+" );
    require( quantity <= CONFIG.maxOrder,       "order too big" );
    require( owners[msg.sender].purchased + quantity <= CONFIG.maxMint, "don't be greedy" );
    require( msg.value >= CONFIG.ethPrice * quantity, "ether sent is not correct" );

    if( CONFIG.isMainsaleActive ){
      //no-op
    }
    else if( CONFIG.isPresaleActive ){
      require( ToddlerPillars.balanceOf( msg.sender ) > 0, "must own ToddlerPillars" );
    }
    else{
      revert( "sale is not active" );
    }

    uint supply = totalSupply();
    require( supply + quantity <= CONFIG.maxSupply, "mint/order exceeds supply" );

    owners[msg.sender].balance += quantity;
    owners[msg.sender].purchased += quantity;
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, tokens.length );
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
      owners[ recipient[i] ].balance += quantity[i];

      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], tokens.length );
      }
    }
  }

  function setConfig( MintConfig calldata config ) external onlyDelegates{
    CONFIG = config;
  }

  function setToddlerPillars( IToddlerPillars principal ) external onlyDelegates {
    ToddlerPillars = principal;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURIPrefix = suffix;
  }

  function transferOwnership( address newOwner ) public override( Delegated, Ownable ) onlyOwner{
    Ownable.transferOwnership( newOwner );
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

  //internal
  function burnFrom( address account, uint[] calldata tokenIds ) external onlyDelegates{
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists( tokenIds[i] ), "Burn for nonexistent token" );
      require( tokens[ tokenIds[i] ].owner == account, "Owner mismatch" );
      _burn( tokenIds[i] );
    }
  }


  function _mint( address to, uint tokenId ) internal override {
    tokens.push(Token( to ));
    emit Transfer(address(0), to, tokenId);
  }
}