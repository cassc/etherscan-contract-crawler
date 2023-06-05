// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import './Blimpie/Delegated.sol';
import './Blimpie/Merkle.sol';
import './Blimpie/ERC721Batch.sol';
import './Blimpie/PaymentSplitterMod.sol';

contract MEFaverse is Delegated, ERC721Batch, Merkle, PaymentSplitterMod {
  using Strings for uint256;

  uint public MAX_MINT   = 2;
  uint public MAX_ORDER  = 2;
  uint public MAX_SUPPLY = 8500;
  uint public PRICE      = 0.08 ether;

  bool public isPresaleActive = false;
  bool public isMainsaleActive = false;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private _accounts = [
    0xE57048340ddf7a28244E1cdC63AA9056187E2665,
    0xbE8Fdf8Ca08c10082b8aD24e2Eb01592153dC8B2,
    0x5B7556FA084116e33aaeB273a511Fdfb35BE0DA0,
    0x42a06F7bB64fd3B862A74e5BcBADc3CFb3F907a4,
    0xf092E151480c9CBf372de602E6c8d048C212a979,
    0x3ff0D4b04D8ef29198C7F8ce597F6FCbA0aF3931,
    0x557e5F91f60dc99aB499F6ffdbedFfBa44b441D9
  ];

  uint[] private _shares = [
    40,
    23,
     8,
    10,
     5,
     4,
    10
  ];

  constructor()
    Delegated()
    ERC721B("MEFaverse", "MEF", 0)
    PaymentSplitterMod( _accounts, _shares ){
  }

  //safety first
  fallback() external payable {}


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "MEFaverse: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function mint( uint quantity, bytes32[] calldata proof ) external payable {
    require( 0 < quantity && quantity <= MAX_ORDER,  "MEFaverse: order too big"             );
    require( msg.value >= PRICE * quantity,          "MEFaverse: ether sent is not correct" );
    require( owners[msg.sender].purchased + quantity <= MAX_MINT, "MEFaverse: don't be greedy" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "MEFaverse: mint/order exceeds supply" );

    if( isMainsaleActive ){
      //no-op
      
    }
    else if( isPresaleActive ){
      verifyProof( keccak256( abi.encodePacked( msg.sender ) ), proof );
    }
    else{
      revert( "MEFaverse: sale is not active" );
    }

    owners[msg.sender].balance += uint16(quantity);
    owners[msg.sender].purchased += uint16(quantity);
    for( uint i; i < quantity; ++i ){
      _safeMint( msg.sender, supply++, "" );
    }
  }


  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "MEFaverse: must provide equal quantities and recipients" );

    unchecked{
      uint totalQuantity;
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      uint supply = totalSupply();
      require( supply + totalQuantity <= MAX_SUPPLY, "MEFaverse: mint/order exceeds supply" );

      for(uint i; i < recipient.length; ++i){
        if( quantity[i] > 0 ){
          owners[recipient[i]].balance += uint16(quantity[i]);
          for( uint j; j < quantity[i]; ++j ){
            _mint( recipient[i], supply++ );
          }
        }
      }
    }
  }

  function setActive(bool isPresaleActive_, bool isMainsaleActive_) external onlyDelegates{
    isPresaleActive = isPresaleActive_;
    isMainsaleActive = isMainsaleActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setConfig(uint maxOrder, uint maxSupply, uint maxMint, uint price) external onlyDelegates{
    require( maxSupply >= totalSupply(), "MEFaverse: specified supply is lower than current balance" );
    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_MINT   = maxMint;
    PRICE      = price;
  }


  //private
  function _mint( address to, uint tokenId ) internal override {
    tokens.push( Token( to ) );
    emit Transfer( address(0), to, tokenId );
  }
}