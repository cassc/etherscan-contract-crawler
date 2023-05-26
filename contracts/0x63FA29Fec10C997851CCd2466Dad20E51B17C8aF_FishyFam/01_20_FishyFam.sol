// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 ****************************************
 *   Blimpie-FF721 provides low-gas     *
 *       mints + transfers              *
 ****************************************/

import "@openzeppelin/contracts/utils/Strings.sol";
import '../Blimpie/Delegated.sol';
import '../Blimpie/PaymentSplitterMod.sol';
import '../Blimpie/Signed.sol';
import './FF721Batch.sol';

contract FishyFam is Delegated, FF721Batch, PaymentSplitterMod, Signed {
  using Strings for uint256;

  uint public PRICE  = 0.03 ether;
  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 10000;
  uint public MAX_WALLET = 3;
  uint public WHALE_WALLET = 15;

  uint public burned;
  bool public isPresaleActive = false;
  bool public isMainsaleActive = false;
  address public whalePass;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private _payees = [
    0x4e1C0E8F7Fd15C04c897d574cb00FA4e01BDC6Bf,
    0xcbAA6a102b62D6e75E6C69D8463f429867ECb2da,
    0x755403F07d03FEcAd97a8d2c9AaeD4611B5CBc69,
    0xA2EC6eDcd18cb379780183BEC8A3bF06fb79cbbD,
    0xA7358eD00BeEfB65CAe0e2bAA8a377276Ef11bbd,
    0xC7f02456dD3FC26aAE2CA1d68528CF9764bf5598,
    0xDaFEbBB4A3bd562FF4c5cDe636BCF63a232A0162
  ];

  uint[] private _shares = [
    32,
    32,
    15,
     8,
     8,
     3,
     2
  ];

  constructor()
    FF721("Fishy Fam", "FF")
    PaymentSplitterMod( _payees, _shares ){
  }


  //view: external
  fallback() external payable {}


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "FishyFam: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //view: IERC721Enumerable
  function totalSupply() public view override returns( uint totalSupply_ ){
    return tokens.length - burned;
  }


  //payable
  function mint( uint quantity, bytes calldata signature ) external payable {
    require( quantity <= MAX_ORDER,             "FishyFam: order too big"             );
    require( msg.value >= PRICE * quantity, "FishyFam: ether sent is not correct" );

    uint max = msg.sender == whalePass ? WHALE_WALLET : MAX_WALLET;
    require( _balances[ msg.sender ] + quantity <= max, "FishyFam: don't be greedy" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "FishyFam: mint/order exceeds supply" );

    if( isMainsaleActive ){
      //no-op
    }
    else if( isPresaleActive ){
      verifySignature( quantity.toString(), signature );
    }
    else{
      revert( "Sale is not active" );
    }

    unchecked{
      for(uint i; i < quantity; ++i){
        _mint( msg.sender, tokens.length );
      }
    }
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
    require(quantity.length == recipient.length, "FishyFam: must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    unchecked{
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    require( supply + totalQuantity < MAX_SUPPLY, "FishyFam: mint/order exceeds supply" );

    unchecked{
      for(uint i; i < recipient.length; ++i){
        for(uint j; j < quantity[i]; ++j){
          _mint( recipient[i], tokens.length );
        }
      }
    }
  }

  function resurrect( address[] calldata recipient, uint[] calldata tokenIds ) external onlyDelegates{
    require(tokenIds.length == recipient.length,   "FishyFam: must provide equal tokenIds and recipients" );

    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        _mint( recipient[i], tokenIds[i] );
      }
    }
  }

  function setActive(bool isPresaleActive_, bool isMainsaleActive_) external onlyDelegates{
    if( isPresaleActive != isPresaleActive_ )
      isPresaleActive = isPresaleActive_;

    if( isMainsaleActive != isMainsaleActive_ )
      isMainsaleActive = isMainsaleActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMax(uint maxOrder, uint maxSupply, uint maxWallet) external onlyDelegates{
    require( maxSupply >= totalSupply(), "FishyFam: specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_WALLET = maxWallet;
  }

  function setPrice( uint price ) external onlyDelegates{
    PRICE = price;
  }

  function setWhale( address whale ) external onlyDelegates{
    whalePass = whale;
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
    require( from == tokens[ tokenId ].owner, "FishyFam: owner mismatch" );
    tokens[ tokenId ].owner = address(0);

    ++burned;
    _beforeTokenTransfer(from, address(0), tokenId);
    tokens[ tokenId ].owner = address(0);
    emit Transfer(from, address(0), tokenId);
  }

  function _mint( address to, uint tokenId ) private {
    if( tokenId < tokens.length ){
      require( !_exists( tokenId ), "FishyFam: can't resurrect existing token" );
      --burned;
      tokens[ tokenId ].owner = to;
    }
    else{
      tokens.push( Token( to ) );
    }

    _beforeTokenTransfer(address(0), to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }
}