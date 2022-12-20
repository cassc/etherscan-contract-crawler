// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IERC721Principal.sol";
import "./IERC721Surrogate.sol";


contract ERC721Surrogate_Upgradeable is IERC721Surrogate, Initializable, UUPSUpgradeable, OwnableUpgradeable {
  using Strings for uint256;

  error NotSupported();

  struct Token {
    address principal;
    address surrogate;
    bool isSet;
  }

  IERC721Principal public PRINCIPAL;

  string internal _tokenURIPrefix;
  string internal _tokenURISuffix;
  mapping( address => int256 ) internal _balances;
  mapping( uint256 => Token ) internal _tokens;

//https://etherscan.io/address/0x70be4e3761188d0a8c525e54bb81c4ea97712de4
  function initialize(IERC721Principal _principal) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    PRINCIPAL = _principal;
    _tokenURIPrefix = "";
    _tokenURISuffix = "";
  }


  //IERC721Surrogate :: nonpayable
  function setSurrogate( uint256 tokenId, address surrogateOwner ) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    require( principalOwner == msg.sender, "ERC721Surrogate: caller is not owner" );

    if( surrogateOwner == principalOwner || surrogateOwner == address(0) ){
      _unsetSurrogate( tokenId, principalOwner );
    }
    else{
      _setSurrogate( tokenId, principalOwner, surrogateOwner );
    }
  }

  function setSurrogates( uint256[] calldata tokenIds, address[] calldata surrogates ) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      setSurrogate( tokenIds[i], surrogates[i] );
    }
  }


  function syncSurrogate( uint256 tokenId ) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    if( _tokens[ tokenId ].principal != principalOwner ){
      _unsetSurrogate( tokenId, principalOwner );
    }
  }

  function syncSurrogates( uint256[] calldata tokenIds ) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      syncSurrogate( tokenIds[i] );
    }
  }


  function unsetSurrogate( uint256 tokenId ) public {
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    require( principalOwner == msg.sender, "ERC721Surrogate: caller is not owner" );
    _unsetSurrogate( tokenId, principalOwner );
  }

  function unsetSurrogates( uint256[] calldata tokenIds ) external {
    for( uint256 i; i < tokenIds.length; ++i ){
      unsetSurrogate( tokenIds[i] );
    }
  }


  //ERC721 :: nonpayable
  function approve(address, uint256) external pure override{
    revert NotSupported();
  }

  function safeTransferFrom( address, address to, uint256 tokenId ) external {
    setSurrogate( tokenId, to );
  }

  function safeTransferFrom( address, address to, uint256 tokenId, bytes calldata ) external {
    setSurrogate( tokenId, to );
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyOwner{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function transferFrom( address, address to, uint256 tokenId ) external {
    setSurrogate( tokenId, to );
  }


  //ERC721 :: nonpayable :: not implemented
  function setApprovalForAll(address, bool) external pure {
    revert NotSupported();
  }


  //ERC721 :: view
  function balanceOf(address account) external view override returns(uint256){
    int256 balance = int256(PRINCIPAL.balanceOf(account)) + _balances[ account ];
    if( balance < 0 )
      return 0;
    else
      return uint256(balance);
  }

  function getApproved(uint256 tokenId) external view override returns(address){
    return PRINCIPAL.ownerOf( tokenId );
  }

  function isApprovedForAll(address, address) external pure override returns(bool){
    return false;
  }

  function name() external view override returns (string memory){
    return PRINCIPAL.name();
  }

  function ownerOf( uint256 tokenId ) external view override returns (address){
    address principalOwner = PRINCIPAL.ownerOf( tokenId );
    Token memory token = _tokens[ tokenId ];
    if( token.principal == principalOwner && token.isSet )
      return token.surrogate;
    else
      return principalOwner;
  }

  function supportsInterface(bytes4 interfaceId) external pure override returns(bool){
    return interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC721).interfaceId
      || interfaceId == type(IERC721Metadata).interfaceId;
  }

  function symbol() external view override returns (string memory){
    return PRINCIPAL.symbol();
  }

  function tokenURI( uint256 tokenId ) external view override returns (string memory) {
    //require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  function totalSupply() external view returns (uint256){
    return PRINCIPAL.totalSupply();
  }


  //internal
  function _setSurrogate( uint256 tokenId, address principalOwner, address surrogateOwner ) internal {
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

  function _unsetSurrogate( uint256 tokenId, address principalOwner ) internal {
    Token memory prev = _tokens[ tokenId ];
    if(prev.isSet){
      --_balances[prev.surrogate];
      ++_balances[prev.principal];
    }

    _tokens[ tokenId ] = Token( principalOwner, principalOwner, false );
    emit Transfer(prev.surrogate, principalOwner, tokenId);
  }


  //internal - admin
  function _authorizeUpgrade(address) internal override onlyOwner {
    // owner check
  }
}