// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Admin.sol";
import "./IOwned.sol";

// Owned by 0xG

contract Owned is Admin, ERC721, IOwned {
  mapping(uint => address) internal _holders;
  mapping(uint => uint) internal _lendingExpires;

  string[] internal _uris = new string[](3);
  address internal _render;

  bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
  address private _royaltiesReceiver;
  uint private _royaltiesBps;
  uint internal _supply;

  constructor() ERC721("Owned", "OWNED") {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == type(IOwned).interfaceId ||
      interfaceId == _INTERFACE_ID_EIP2981 ||
      ERC721.supportsInterface(interfaceId);
  }

  function ownerOf(uint tokenId) public view virtual override returns (address) {
    address holder = _holders[tokenId];
    require(holder != address(0), "ERC721: owner query for nonexistent token");
    return holder;
  }

  function tokenInfo(uint tokenId) external view virtual override returns (
    address owner,
    address holder,
    uint expire
  ) {
    return (ERC721.ownerOf(tokenId), _holders[tokenId], _lendingExpires[tokenId]);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint tokenId
  ) internal virtual override {
    if (from != address(0)) {
      require(ERC721.ownerOf(tokenId) == _holders[tokenId], "Owned: transfer of lent token");
    }
    _holders[tokenId] = to;
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(ERC721.balanceOf(msg.sender) > 0, "Owned: caller not owner of a token");
    ERC721.setApprovalForAll(operator, approved);
  }

  function approve(address to, uint256 tokenId) public virtual override {
    require(block.timestamp > _lendingExpires[tokenId], "Owned: token locked until lending expiration");
    ERC721.approve(to, tokenId);
  }

  function lend(address to, uint tokenId, uint expire) external override {
    require(to != address(0) && to != address(0xdead), "Owned: lend to burn address not allowed");
    require(block.timestamp > _lendingExpires[tokenId], "Owned: token locked until lending expiration");

    require(_isApprovedOrOwner(msg.sender, tokenId), "Owned: lend caller is not owner nor approved");

    address owner = ERC721.ownerOf(tokenId);
    address holder = _holders[tokenId];

    _holders[tokenId] = to;
    _lendingExpires[tokenId] = expire;

    if (owner != holder) {
      emit Transfer(holder, owner, tokenId);
    }
    emit Transfer(owner, to, tokenId);
    emit Lend(owner, to, tokenId, expire);
  }

  function claim(uint tokenId) external override {
    require(block.timestamp > _lendingExpires[tokenId], "Owned: token locked until lending expiration");

    address owner = ERC721.ownerOf(tokenId);
    require(owner == msg.sender, 'Owned: claim caller is not owner');
    address holder = _holders[tokenId];
    require(owner != holder, 'Owned: claim caller is already holder');

    _lendingExpires[tokenId] = 0;
    _holders[tokenId] = owner;

    emit Transfer(holder, owner, tokenId);
    emit Claim(owner, holder, tokenId);
  }

  function returnToken(uint tokenId) external override {
    address holder = _holders[tokenId];
    require(holder == msg.sender, "Owned: caller not holder of token");
    address owner = ERC721.ownerOf(tokenId);

    _lendingExpires[tokenId] = 0;
    _holders[tokenId] = owner;

    emit Transfer(holder, owner, tokenId);
    emit ReturnToken(holder, owner, tokenId);
  }

  function mint(address to, uint tokenId) external override adminOnly {
    _supply += 1;
    _safeMint(to, tokenId);
    emit Mint(owner(), to, tokenId);
  }

  function burn(uint tokenId) external override {
    address owner = ERC721.ownerOf(tokenId);
    require(owner == msg.sender, "Owned: caller not owner");
    require(block.timestamp > _lendingExpires[tokenId], "Owned: token locked until lending expiration");

    _supply -= 1;
    _lendingExpires[tokenId] = 0;

    address holder = _holders[tokenId];
    if (owner != holder) {
      emit Transfer(holder, owner, tokenId);
    }

    _burn(tokenId);
  }

  function supply() external view override returns (uint) {
    return _supply;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (_render != address(0)) {
      return IRender(_render)
        .render(tokenId, ERC721.ownerOf(tokenId), _holders[tokenId], _lendingExpires[tokenId]);
    }

    return _uris[ERC721.ownerOf(tokenId) == _holders[tokenId] ? 0 : _lendingExpires[tokenId] == 0 ? 1 : 2];
  }

  function setTokenURIs(string[] memory uris) external adminOnly {
    _uris = uris;
  }

  function setRender(address render_) external adminOnly {
    _render = render_;
  }

  function royaltyInfo(uint256, uint256 value) public view returns (address, uint256) {
    if (_royaltiesReceiver == address(0)) return (address(0), 0);
    return (_royaltiesReceiver, _royaltiesBps*value/10000);
  }

  function setRoyalties(address receiver, uint256 bps) external adminOnly {
    _royaltiesReceiver = receiver;
    _royaltiesBps = bps;
  }
}

interface IRender {
  function render(uint tokenId, address owner, address holder, uint until) external view returns (string memory);
}