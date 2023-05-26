// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './Delegated.sol';
import './PaymentSplitterMod.sol';
import './Merkle.sol';
import './FF721Batch.sol';

contract FelineFiendz is Delegated, FF721Batch, Merkle, PaymentSplitterMod {
  using Strings for uint256;

  //EIP-2309
  event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

  uint public PRICE  = 0.05 ether;
  uint public MAX_ORDER  = 3;
  uint public MAX_SUPPLY = 7777;
  uint public MAX_MINT = 3;

  uint public burned;
  bool public isPresaleActive = false;
  bool public isMainsaleActive = false;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private _payees = [
    0x493b641091483A6855a382fC920E2f1e5D10a059,
    0x10e220d130b8210Ad4D741082264c1e05E33dCcE,
    0x6E894E887C24F0F71B6bE4D54DE8fE039631E155,
    0xCEf9b5c629664b415dc8d456b5f139154f8D8F0C,
    0x6210d6717D2a20FB7Ead2AD01ba413eA64f8F1e1,
    0xFB58FE5251717A4f2404e6F488048838079a7727,
    0x102DD33ef3c1af8736EDdCc30985fEB69e099cD8
  ];

  uint[] private _shares = [
    1966,
    1966,
    1966,
    1966,
     983,
     983,
      17
  ];

  constructor()
    FF721("Feline Fiendz", "FF")
    PaymentSplitterMod( _payees, _shares ){
  }


  //view: external
  fallback() external payable {}


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "FelineFiendz: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //view: IERC721Enumerable
  function totalSupply() public view override returns( uint totalSupply_ ){
    return tokens.length - burned;
  }


  //payable
  function mint( uint quantity, bytes32[] calldata proof ) external payable {
    require( 0 < quantity && quantity <= MAX_ORDER,  "FelineFiendz: order too big"             );
    require( msg.value >= PRICE * quantity,          "FelineFiendz: ether sent is not correct" );
    require( owners[ msg.sender ].purchased + quantity <= MAX_MINT, "FelineFiendz: don't be greedy" );
    require( totalSupply() + quantity <= MAX_SUPPLY, "FelineFiendz: mint/order exceeds supply" );

    if( isMainsaleActive ){
      //no-op
    }
    else if( isPresaleActive ){
      verifyProof( keccak256( abi.encodePacked( msg.sender ) ), proof );
    }
    else{
      revert( "FelineFiendz: sale is not active" );
    }

    _mintN( msg.sender, quantity, true );
  }


  //onlyDelegates
  function burnFrom( address account, uint[] calldata tokenIds ) external onlyDelegates{
    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        _burn( account, tokenIds[i] );
      }
    }
  }

  function mintTo(address[] calldata recipient, uint[] calldata quantity) external payable onlyDelegates{
    require(quantity.length == recipient.length, "FelineFiendz: must provide equal quantities and recipients" );

    unchecked{
      uint totalQuantity;
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      require( totalSupply() + totalQuantity <= MAX_SUPPLY, "FelineFiendz: mint/order exceeds supply" );

      for(uint i; i < recipient.length; ++i){
        if( quantity[i] > 0 )
          _mintN( recipient[i], quantity[i], false );
      }
    }
  }

  function resurrect( address[] calldata recipient, uint[] calldata tokenIds ) external onlyDelegates{
    require(tokenIds.length == recipient.length,   "FelineFiendz: must provide equal tokenIds and recipients" );

    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        _resurrect( recipient[i], tokenIds[i] );
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
    require( maxSupply >= totalSupply(), "FelineFiendz: specified supply is lower than current balance" );
    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_MINT   = maxMint;
    PRICE      = price;
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


  //private
  function _burn( address from, uint tokenId ) private {
    require( from == tokens[ tokenId ].owner, "FelineFiendz: owner mismatch" );
    tokens[ tokenId ].owner = address(0);

    ++burned;
    _beforeTokenTransfer(from, address(0));
    tokens[ tokenId ].owner = address(0);
    emit Transfer(from, address(0), tokenId);
  }


  function _mint( address to, uint tokenId ) private {
    tokens.push( Token( to ) );
    emit Transfer(address(0), to, tokenId);
  }

  function _mintN( address to, uint quantity, bool isPurchase ) private {
    unchecked{
      uint fromToken = tokens.length;
      uint toToken = fromToken + quantity - 1;

      if( isPurchase )
        owners[to].purchased += uint16(quantity);

      owners[to].balance += uint16(quantity);
      for(uint i; i < quantity; ++i){
        tokens.push( Token( to ) );
      }

      emit ConsecutiveTransfer( fromToken, toToken, address(0), to );
    }
  }

  function _resurrect( address to, uint tokenId ) private {
    require( !_exists( tokenId ), "FelineFiendz: can't resurrect existing token" );
    --burned;
    tokens[ tokenId ].owner = to;

    _beforeTokenTransfer(address(0), to);
    emit Transfer(address(0), to, tokenId);
  }
}