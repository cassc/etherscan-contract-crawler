// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IERC721Batch} from "../Common/ERC721/IERC721Batch.sol";

abstract contract FuturistsData{
  enum SaleState {
    NONE,
    ALLOWLIST,
    PUBLIC
  }

  struct MintConfig{
    uint64 ethPrice;
    uint8 maxOrder;
    uint8 maxWallet;
    uint16 maxSupply;
    uint8 saleState;
  }

  struct Owner{
    uint16 balance;
    uint16 purchased;
    uint16 redeemed;
    uint16 vouchers;
  }

  struct TokenRange{
    uint16 lower;
    uint16 upper;
    uint16 supply;
  }

  struct Token{
    address owner;
    uint16 id;
  }

  uint256 public constant MAX_SUPPLY = 10000;

  address public crossmintOperator = 0xdAb1a1854214684acE522439684a145E62505233;
  bool public isOsEnabled = true;
  uint16 public reserved = 200;
  string public tokenURIPrefix;
  string public tokenURISuffix;

  mapping(uint256 => Token) public tokens;
  mapping(address => Owner) public owners;

  MintConfig public CONFIG = MintConfig(
       1 ether,  //ethPrice
       1,        //maxOrder
       1,        //maxWallet
    1111,        //maxSupply
       0         //saleState
  );

  TokenRange public range = TokenRange(
    1, //lower
    0, //upper
    0  //supply
  );
}

abstract contract Futurists721 is FuturistsData, Context, ERC165, IERC721, IERC721Metadata {
  error CantApproveOwner();
  error NotERC721Receiver();
  error NotOwnerOrApproved();
  error TokenNonexistant();
  error TokenNotOwned();
  error TokenExists();
  error ZeroAddress();

  string public name;
  string public symbol;

  mapping(uint256 => address) internal _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(){
    name = "Future Factory Futurists";
    symbol = "FUTUR";
  }

  //public view
  function balanceOf(address owner) public view returns(uint256){
    if(owner == address(0)) revert ZeroAddress();
    return owners[owner].balance;
  }

  function burned() public view returns(uint256){
    return owners[address(0)].balance;
  }

  function ownerOf(uint256 tokenId) public view virtual returns(address){
    if(!_exists(tokenId)) revert TokenNonexistant();
    return tokens[tokenId].owner;
  }

  // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool){
  //   return
  //     interfaceId == type(IERC721).interfaceId ||
  //     interfaceId == type(IERC721Metadata).interfaceId ||
  //     super.supportsInterface(interfaceId);
  // }

  function totalSupply() public view virtual returns( uint256 ){
    return range.supply - burned();
  }


  //approvals
  function approve(address operator, uint256 tokenId) public virtual{
    address owner = tokens[tokenId].owner;
    if(operator == owner) revert CantApproveOwner();

    if(_msgSender() == owner)
      _approve(operator, tokenId);
    else if(isApprovedForAll(owner, _msgSender()))
      _approve(operator, tokenId);
    else 
      revert NotOwnerOrApproved();
  }

  function getApproved(uint256 tokenId) public view returns(address){
    if(!_exists(tokenId)) revert TokenNonexistant();
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) public view returns(bool){
    return _operatorApprovals[owner][operator];
  }

  function setApprovalForAll(address operator, bool approved) public virtual{
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }


  //transfers
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual{
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual{
    if(!_isApprovedOrOwner(_msgSender(), tokenId)) revert NotOwnerOrApproved();

    _safeTransfer(from, to, tokenId, _data);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual{
    if(!_isApprovedOrOwner(_msgSender(), tokenId)) revert NotOwnerOrApproved();

    _transfer(from, to, tokenId);
  }


  //internal
  function _approve(address to, uint256 tokenId) internal{
    _tokenApprovals[tokenId] = to;
    emit Approval(tokens[tokenId].owner, to, tokenId);
  }

  // solhint-disable-next-line no-empty-blocks
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

  function _burn(address from, uint256 tokenId) internal{
    if(ownerOf(tokenId) != from) revert TokenNotOwned();

    // Clear approvals
    delete _tokenApprovals[tokenId];
    _beforeTokenTransfer(from, address(0), tokenId);

    _transfer(from, address(0), tokenId);
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
    if (Address.isContract(to)) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert NotERC721Receiver();
        } else {
          // solhint-disable-next-line no-inline-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _exists(uint256 tokenId) internal view returns(bool) {
    return range.lower <= tokenId
      && tokenId <= range.upper
      && tokens[tokenId].owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns(bool) {
    if(!_exists(tokenId)) revert TokenNonexistant();

    address owner = tokens[tokenId].owner;
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mintSpecific(uint16 tokenId, address to, bool isPurchase) internal {
    if(_exists(tokenId))
      revert TokenExists();


    TokenRange memory _range = range;
    ++_range.supply;
    if(_range.lower > tokenId)
      _range.lower = tokenId;

    if(_range.upper < tokenId)
      _range.upper = tokenId;


    Owner memory prev = owners[to];
    owners[to] = Owner(
      prev.balance + 1,
      isPurchase ? prev.purchased + 1 : prev.purchased,
      isPurchase ? prev.redeemed : prev.redeemed + 1,
      prev.vouchers
    );

    range = _range;

    tokens[tokenId] = Token(
      to,
      tokenId
    );
    _beforeTokenTransfer(address(0), to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
    _transfer(from, to, tokenId);
    if(!_checkOnERC721Received(from, to, tokenId, _data))
      revert NotERC721Receiver();
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual {
    if(tokens[tokenId].owner != from) revert TokenNotOwned();

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];
    _beforeTokenTransfer(from, to, tokenId);

    unchecked{
      --owners[from].balance;
      ++owners[to].balance;
    }

    tokens[tokenId].owner = to;
    emit Transfer(from, to, tokenId);
  }
}

abstract contract FuturistsEnumerable is Futurists721, IERC721Enumerable {
  error IndexOutOfBounds();

  //function balanceOf(address) public returns(uint256);

  // function supportsInterface(bytes4 interfaceId) public view virtual override(Futurists721, IERC165) returns(bool) {
  //   return interfaceId == type(IERC721Enumerable).interfaceId
  //     || super.supportsInterface(interfaceId);
  // }

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256) {
    if(balanceOf(owner) <= index) revert IndexOutOfBounds();

    uint256 count;
    uint256 tokenId;
    for(tokenId = range.lower; tokenId < range.upper; ++tokenId){
      if( owner != tokens[tokenId].owner )
        continue;

      if( index == count++ )
        break;
    }
    return tokenId;
  }

  function tokenByIndex(uint256 index) external view returns(uint256) {
    if(!_exists(index + range.lower)) revert TokenNonexistant();
    return range.lower + index;
  }

  function totalSupply() public view override(Futurists721, IERC721Enumerable) returns(uint256){
    return Futurists721.totalSupply();
  }
}

abstract contract FuturistsBatch is FuturistsEnumerable, IERC721Batch {
  function isOwnerOf(address account, uint256[] calldata tokenIds) external view returns(bool) {
    for(uint256 i = 0; i < tokenIds.length; ++i){
      if(account != Futurists721.ownerOf(tokenIds[i]))
        return false;
    }

    return true;
  }

  function safeTransferBatch(address from, address to, uint256[] calldata tokenIds, bytes calldata data) external {
    for(uint i; i < tokenIds.length; ++i){
      safeTransferFrom(from, to, tokenIds[i], data);
    }
  }

  function transferBatch(address from, address to, uint256[] calldata tokenIds) external {
    for(uint i; i < tokenIds.length; ++i){
      transferFrom(from, to, tokenIds[i]);
    }
  }

  function walletOfOwner(address account) external view returns(uint[] memory) {
    uint256 count;
    uint256 quantity = owners[ account ].balance;
    uint256[] memory wallet = new uint256[](quantity);
    for(uint256 i = range.lower; i < range.upper; ++i){
      if(account == tokens[i].owner){
        wallet[ count++ ] = i;
        if(count == quantity)
          break;
      }
    }
    return wallet;
  }
}