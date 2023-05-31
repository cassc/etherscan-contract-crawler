// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import './Blimpie/Delegated.sol';
import './Blimpie/ERC721Batch.sol';
import './Blimpie/SignedSecret.sol';

contract JustGreg is Delegated, ERC721Batch, SignedSecret {
  using Strings for uint256;

  uint public ETH_PRICE  = 0.0 ether;
  uint public MAX_MINT   = 1;
  uint public MAX_ORDER  = 1;
  uint public MAX_SUPPLY = 1234;

  bool public isPresaleActive;
  bool public isMainsaleActive;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  constructor()
    ERC721B( "Just Greg", "GREG", 0 )
    SignedSecret( 0xBf5F724DAa9760Fc231699199b00f577be09BB1b, "Can you believe they put a man on the moon" ){
  }


  //safety first
  receive() external payable {}

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "no funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function mint( uint16 quantity, bytes calldata signature ) external payable {
    require( quantity > 0,                      "must order 1+" );
    require( quantity <= MAX_ORDER,             "order too big" );
    require( owners[msg.sender].purchased + quantity <= MAX_MINT, "don't be greedy" );
    require( msg.value >= ETH_PRICE * quantity, "ether sent is not correct" );

    if( isMainsaleActive ){

    }
    else if( isPresaleActive ){
      require( _isAuthorizedSigner( uint(quantity).toString(), signature ),  "account not authorized" );
    }
    else{
      revert( "sale is not active" );
    }

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "mint/order exceeds supply" );

    owners[msg.sender].balance += quantity;
    owners[msg.sender].purchased += quantity;
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, tokens.length );
    }
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "must provide equal quantities and recipients" );

    uint totalQuantity;
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }

    uint supply = totalSupply();
    require( supply + totalQuantity < MAX_SUPPLY, "mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      if( quantity[i] > 0 ){
        owners[recipient[i]].balance += quantity[i];
        for(uint j; j < quantity[i]; ++j){
          _mint( recipient[i], tokens.length );
        }
      }
    }
  }

  function setConfig( bool isPresaleActive_, bool isMainsaleActive_,
    uint maxMint_, uint maxOrder_, uint maxSupply_, uint price_ ) external onlyDelegates{
    require( maxSupply_ >= totalSupply(), "specified supply is lower than current balance" );

    isPresaleActive = isPresaleActive_;
    isMainsaleActive = isMainsaleActive_;
    
    MAX_MINT = maxMint_;
    MAX_ORDER = maxOrder_;
    MAX_SUPPLY = maxSupply_;

    ETH_PRICE = price_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function transferOwnership( address newOwner ) public override( Delegated, Ownable ) onlyOwner{
    Ownable.transferOwnership( newOwner );
  }


  //private
  function _mint( address to, uint tokenId ) internal override {
    tokenId = tokens.length;

    tokens.push( Token( to ) );
    emit Transfer(address(0), to, tokenId);
  }
}