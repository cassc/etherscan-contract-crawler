// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721Surrogate.sol";

contract ERC721Surrogate is IERC721Surrogate, Ownable {
  using Strings for uint256;

  error NotSupported();

  struct Token {
    address principal;
    address surrogate;
    bool isSet;
  }

  IERC721Metadata public PRINCIPAL;

  string internal _tokenURIPrefix;
  string internal _tokenURISuffix;
  mapping( address => int256 ) internal _balances;
  mapping( uint256 => Token ) internal _tokens;

  constructor(IERC721Metadata _principal)
    Ownable(){
    PRINCIPAL = _principal;
    _tokenURIPrefix = "";
    _tokenURISuffix = "";
  }


  //IERC721Surrogate :: nonpayable
  function setSurrogate(uint256 tokenId, address surrogateOwner) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    require( principalOwner == msg.sender, "ERC721Surrogate: caller is not owner" );

    if( surrogateOwner == principalOwner || surrogateOwner == address(0) ){
      _unsetSurrogate( tokenId, principalOwner );
    }
    else{
      _setSurrogate( tokenId, principalOwner, surrogateOwner );
    }
  }

  function setSurrogates(uint256[] calldata tokenIds, address[] calldata surrogates) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      setSurrogate( tokenIds[i], surrogates[i] );
    }
  }


  function softSync(uint256 tokenId) public {
    if(_tokens[tokenId].principal == address(0))
      emit Transfer(address(0), PRINCIPAL.ownerOf(tokenId), tokenId);
  }

  function softSync(uint[] calldata tokenIds) external {
    for(uint256 i; i < tokenIds.length; ++i){
      softSync(tokenIds[i]);
    }
  }


  function syncSurrogate(uint256 tokenId) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    if( _tokens[ tokenId ].principal != principalOwner ){
      _unsetSurrogate( tokenId, principalOwner );
    }
  }

  function syncSurrogates(uint256[] calldata tokenIds) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      syncSurrogate( tokenIds[i] );
    }
  }


  function unsetSurrogate(uint256 tokenId) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    require( principalOwner == msg.sender, "ERC721Surrogate: caller is not owner" );
    _unsetSurrogate( tokenId, principalOwner );
  }

  function unsetSurrogates(uint256[] calldata tokenIds) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      unsetSurrogate( tokenIds[i] );
    }
  }


  //ERC721 :: nonpayable
  function approve(address, uint256) external pure override {
    revert NotSupported();
  }

  function safeTransferFrom(address, address to, uint256 tokenId) external {
    setSurrogate( tokenId, to );
  }

  function safeTransferFrom(address, address to, uint256 tokenId, bytes calldata) external {
    setSurrogate( tokenId, to );
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyOwner {
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function transferFrom(address, address to, uint256 tokenId) external {
    setSurrogate( tokenId, to );
  }


  //ERC721 :: nonpayable :: not implemented
  function setApprovalForAll(address, bool) external pure {
    revert NotSupported();
  }


  //ERC721 :: view
  function balanceOf(address account) public view override returns(uint256) {
    int256 balance = int256(PRINCIPAL.balanceOf(account)) + _balances[ account ];
    if( balance < 0 )
      return 0;
    else
      return uint256(balance);
  }

  function getApproved(uint256 tokenId) external view override returns(address) {
    return PRINCIPAL.ownerOf( tokenId );
  }

  function isApprovedForAll(address, address) external pure override returns(bool) {
    return false;
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    Token memory token = _tokens[ tokenId ];
    if( token.principal == principalOwner && token.isSet )
      return token.surrogate;
    else
      return principalOwner;
  }


  //ERC721Metadata :: view
  function name() external view override returns (string memory) {
    return PRINCIPAL.name();
  }

  function symbol() external view override returns (string memory) {
    return PRINCIPAL.symbol();
  }

  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    PRINCIPAL.tokenURI(tokenId);
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //ERC721Enumerable :: view
  function tokenByIndex(uint256 index) external view returns (uint256) {
    if(!PRINCIPAL.supportsInterface(type(IERC721Enumerable).interfaceId))
      revert NotSupported();

    return IERC721Enumerable(address(PRINCIPAL)).tokenByIndex(index);    
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    require(balanceOf(owner) > index, "ERC721Enumerable: owner index out of bounds" );

    uint256 count;
    uint256 tokenId;
    uint256 supply = totalSupply();
    for(tokenId = 0; tokenId < supply; ++tokenId){
      if(ownerOf(tokenId) == owner){
        if(index == count++)
          return tokenId;
      }
    }

    revert( "ERC721Enumerable: owner index out of bounds" );
  }

  function totalSupply() public view returns (uint256){
    if(!PRINCIPAL.supportsInterface(type(IERC721Enumerable).interfaceId))
      revert NotSupported();

    return IERC721Enumerable(address(PRINCIPAL)).totalSupply();      
  }


  //ERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
    return interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC721).interfaceId
      || interfaceId == type(IERC721Metadata).interfaceId
      || interfaceId == type(IERC721Enumerable).interfaceId;
  }


  //internal
  function _setSurrogate(uint256 tokenId, address principalOwner, address surrogateOwner) internal {
    Token memory prev = _tokens[ tokenId ];
    if(prev.principal != principalOwner){
      if(prev.principal != address(0))
        ++_balances[prev.principal];
      
      --_balances[principalOwner];
    }

    if(prev.surrogate != surrogateOwner){
      if(prev.surrogate != address(0))
        --_balances[prev.surrogate];
      
      ++_balances[surrogateOwner];
    }

    _tokens[ tokenId ] = Token(principalOwner, surrogateOwner, true);
    emit Transfer(prev.surrogate, surrogateOwner, tokenId);
  }

  function _unsetSurrogate(uint256 tokenId, address principalOwner) internal {
    Token memory prev = _tokens[ tokenId ];
    if(prev.isSet){
      --_balances[prev.surrogate];
      ++_balances[prev.principal];
    }

    _tokens[ tokenId ] = Token( principalOwner, principalOwner, false );
    emit Transfer(prev.surrogate, principalOwner, tokenId);
  }
}