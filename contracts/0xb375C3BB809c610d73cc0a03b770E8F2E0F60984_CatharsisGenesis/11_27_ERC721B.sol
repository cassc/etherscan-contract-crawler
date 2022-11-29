// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


abstract contract ERC721B is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;

  struct Owner{
    uint16 balance;
    uint16 purchased;
  }

  struct TokenRange{
    uint16 lower;
    uint16 current;
    uint16 upper;
    uint16 minted;
  }

  struct Token{
    address owner;        //160
    uint16 model;         //192
  }

  TokenRange public range;
  mapping(uint256 => Token) public tokens;
  mapping(address => Owner) public owners;

  string private _name;
  string private _symbol;

  mapping(uint256 => address) internal _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_ ){
    _name = name_;
    _symbol = symbol_;

    range = TokenRange(
      0,
      0,
      0,
      0
    );
  }

  //public view
  function balanceOf(address owner) external view returns( uint256 balance ){
    require(owner != address(0), "ERC721B: balance query for the zero address");
    return owners[owner].balance;
  }

  function burned() public view returns(uint256){
    return owners[address(0)].balance;
  }

  function name() external view returns( string memory name_ ){
    return _name;
  }

  function ownerOf(uint256 tokenId) public view virtual returns( address owner ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    return tokens[tokenId].owner;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns( bool isSupported ){
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function symbol() external view returns( string memory symbol_ ){
    return _symbol;
  }

  function totalSupply() public view virtual returns( uint256 ){
    return range.minted - burned();
  }


  //approvals
  function approve(address operator, uint256 tokenId) public virtual{
    address owner = tokens[tokenId].owner;
    require(operator != owner, "ERC721B: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721B: caller is not owner nor approved for all"
    );

    _approve(operator, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns( address approver ){
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) public view returns( bool isApproved ){
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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual{
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }


  //internal
  function _approve(address to, uint256 tokenId) internal{
    _tokenApprovals[tokenId] = to;
    emit Approval(tokens[tokenId].owner, to, tokenId);
  }

  // solhint-disable-next-line no-empty-blocks
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

  function _burn( address from, uint256 tokenId ) internal{
    require(ownerOf(tokenId) == from, "ERC721B: burn of token that is not own");
    
    // Clear approvals
    delete _tokenApprovals[tokenId];
    _beforeTokenTransfer(from, address(0), tokenId);

    _transfer( from, address(0), tokenId );
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns( bool ){
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721B: transfer to non ERC721Receiver implementer");
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

  function _exists(uint256 tokenId) internal view returns( bool ){
    return range.lower <= tokenId
      && tokenId <= range.upper
      && tokens[tokenId].owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns( bool isApproved ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    address owner = tokens[tokenId].owner;
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mintSequential( address recipient, uint16 quantity, bool isPurchase ) internal{
    Owner memory prev = owners[recipient];
    TokenRange memory _range = range;

    uint16 tokenId = _range.current;
    uint16 endTokenId = tokenId + quantity;

    unchecked{
      owners[recipient] = Owner(
        prev.balance + quantity,
        isPurchase ? prev.purchased + quantity : prev.purchased
      );

      range = TokenRange(
        _range.lower,
        endTokenId,
        _range.upper > endTokenId ? _range.upper : endTokenId,
        _range.minted + quantity
      );
    }

    for(; tokenId < endTokenId; ++tokenId ){
      tokens[ tokenId ] = Token(
        recipient,
        0
      );
      _beforeTokenTransfer(address(0), recipient, tokenId);
      emit Transfer( address(0), recipient, tokenId );
    }
  }

  function _next() internal virtual returns(uint256 current){
    return range.current;
  }

  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal{
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721B: transfer to non ERC721Receiver implementer");
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual{
    require(tokens[tokenId].owner == from, "ERC721B: transfer of token that is not own");

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

  function _updateRange(uint256 tokenId) private{
    TokenRange memory prev = range;
    ++prev.minted;

    if( tokenId <= prev.current )
      ++prev.current;

    if( tokenId > prev.upper )
      prev.upper = uint16(tokenId + 1);


    range = TokenRange(
      prev.current,
      prev.minted,
      prev.lower,
      prev.upper
    );
  }
}