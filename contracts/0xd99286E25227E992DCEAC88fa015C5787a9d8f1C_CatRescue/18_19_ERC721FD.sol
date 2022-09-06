// SPDX-License-Identifier: MIT

// ERC721FD extends ERC721 for devMint.

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

abstract contract ERC721FD is ERC721 {
  using Counters for Counters.Counter;

  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;

  uint256 private immutable _devMintInventory;
  address private _devMintAddress;
  Counters.Counter private _devMintReleasedCount;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 devMintInventory_
  ) ERC721(name_, symbol_) {
    _devMintInventory = devMintInventory_;
  }

  function devMintAddress_() internal view returns (address) {
    return _devMintAddress;
  }

  function _setDevMintAddress(address to) internal {
    require(
      _underlyingOwnerbalanceOf(to) == 0,
      'ERC721FD: devMintAddress should be empty'
    );
    address prevAddress = _devMintAddress;
    _devMintAddress = to;

    uint256 max = devMintInventory();
    for (uint256 id = 1; id <= max; id++) {
      emit Transfer(prevAddress, to, id);
    }
  }

  function devMintReleasedCount_() internal view returns (uint256) {
    return _devMintReleasedCount.current();
  }

  function incrementDevMintReleasedCount_() internal {
    _devMintReleasedCount.increment();
  }

  function decrementDevMintReleasedCount_() internal {
    _devMintReleasedCount.decrement();
  }

  function devMintInventory() public view virtual returns (uint256) {
    return _devMintInventory;
  }

  function _underlyingOwnerbalanceOf(address owner)
    internal
    view
    virtual
    returns (uint256)
  {
    return _balances[owner];
  }

  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    if (owner == _devMintAddress) {
      return
        _devMintInventory - _devMintReleasedCount.current() + _balances[owner];
    } else {
      return _balances[owner];
    }
  }

  function _underlyingOwnerOf(uint256 tokenId) internal view returns (address) {
    return _owners[tokenId];
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    if (_owners[tokenId] == address(0) && tokenId <= _devMintInventory) {
      owner = _devMintAddress;
    }
    require(owner != address(0), 'ERC721: owner query for nonexistent token');
    return owner;
  }

  // [Use openzeppelin's methods directly]
  // name() public view virtual override returns (string memory
  // symbol() public view virtual override returns (string memory)
  // tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
  // _baseURI() internal view virtual returns (string memory) {

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'ERC721: approve caller is not owner nor approved for all'
    );

    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(
      ERC721FD._exists(tokenId),
      'ERC721: approved query for nonexistent token'
    );

    return _tokenApprovals[tokenId];
  }

  // [Use openzeppelin's methods directly]
  // setApprovalForAll(address operator, bool approved) public virtual override {
  // isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
  // transferFrom(address from, address to, uint256 tokenId) public virtual override {
  // safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
  // safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
  // _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {

  function _exists(uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bool)
  {
    return
      _owners[tokenId] != address(0) ||
      (tokenId <= _devMintInventory && _devMintAddress != address(0));
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bool)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
    address owner = ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  // [Use openzeppelin's methods directly]
  // _safeMint(address to, uint256 tokenId) internal virtual {
  // _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {

  function _mint(address to, uint256 tokenId) internal virtual override {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    _approve(address(0), tokenId);

    if (tokenId <= _devMintInventory && _owners[tokenId] == address(0)) {
      _devMintReleasedCount.increment();
    } else {
      _balances[owner] -= 1;
      delete _owners[tokenId];
    }

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId);

    _approve(address(0), tokenId);

    if (from != to) {
      if (tokenId <= _devMintInventory) {
        if (from == _devMintAddress) {
          _devMintReleasedCount.increment();
        } else {
          _balances[from] -= 1;
        }

        if (to == _devMintAddress) {
          _devMintReleasedCount.decrement();
          delete _owners[tokenId];
        } else {
          _owners[tokenId] = to;
          _balances[to] += 1;
        }
      } else {
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
      }
    }

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal virtual override {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  // [Use openzeppelin's methods directly]
  // _setApprovalForAll(address owner,address operator, bool approved) internal virtual
  // _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
}