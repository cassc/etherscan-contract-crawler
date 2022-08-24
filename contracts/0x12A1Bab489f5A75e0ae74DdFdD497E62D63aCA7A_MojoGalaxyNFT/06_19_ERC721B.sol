// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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
    uint16 claimed;
    uint16 purchased;
  }

  struct Token{
    address owner;
  }

  //Token[] public tokens;
  Token[] public tokens;
  mapping(address => Owner) public owners;

  string private _name;
  string private _symbol;

  mapping(uint256 => address) internal _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_ ){
    _name = name_;
    _symbol = symbol_;
  }

  //public view
  function balanceOf(address owner) external view override returns( uint256 balance ){
    require(owner != address(0), "ERC721B: balance query for the zero address");
    return owners[owner].balance;
  }

  function name() external view override returns( string memory name_ ){
    return _name;
  }

  function ownerOf(uint256 tokenId) public view override returns( address owner ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    return tokens[tokenId].owner;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns( bool isSupported ){
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function symbol() external view override returns( string memory symbol_ ){
    return _symbol;
  }

  function totalSupply() public view virtual returns( uint256 ){
    return tokens.length;
  }


  //approvals
  function approve(address to, uint tokenId) external override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721B: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721B: caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view override returns( address approver ){
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) public view override returns( bool isApproved ){
    return _operatorApprovals[owner][operator];
  }

  function setApprovalForAll(address operator, bool approved) external override {
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }


  //transfers
  function safeTransferFrom(address from, address to, uint256 tokenId) external override{
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721B: caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }


  //internal
  function _approve(address to, uint tokenId) internal{
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
  }


  /*
  function _burn(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from, "ERC721B: burn of token that is not own");
    
    // Clear approvals
    delete _tokenApprovals[tokenId];
    _beforeTokenTransfer(from, address(0), tokenId);

    ++_burned;
    --owners[ from ].balance;
    tokens[tokenId].owner = address(0);
    emit Transfer(from, address(0), tokenId);
  }
  */

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns( bool ){
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721B: transfer to non ERC721Receiver implementer");
        } else {
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
    return tokenId < tokens.length && tokens[tokenId].owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns( bool isApproved ){
    require(_exists(tokenId), "ERC721B: query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mint( address to ) internal virtual{
    uint256 tokenId = tokens.length;

    _beforeTokenTransfer(address(0), to, tokenId);
    tokens.push( Token( to ) );
    emit Transfer( address(0), to, tokenId );
  }

  function _safeMint(address to, uint tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(address to, uint tokenId, bytes memory _data) internal {
    _mint(to);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721B: transfer to non ERC721Receiver implementer"
    );
  }

  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal{
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721B: transfer to non ERC721Receiver implementer");
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual {
    require(ownerOf(tokenId) == from, "ERC721B: transfer of token that is not own");

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];
    _beforeTokenTransfer(from, to, tokenId);

    unchecked {
      --owners[from].balance;
      ++owners[to].balance;
    }

    tokens[tokenId].owner = to;
    emit Transfer(from, to, tokenId);
  }
}