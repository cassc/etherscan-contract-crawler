// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";

contract SimpleERC721 is IOwnable {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  address implementation_;
  address public admin;

  string public name;
  string public symbol;

  mapping(address => uint256) public balanceOf;
  mapping(uint256 => address) public ownerOf;
  mapping(uint256 => address) public getApproved;
  mapping(address => mapping(address => bool)) public isApprovedForAll;

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view override returns (address) {
    return admin;
  }

  function transferOwnership(address newOwner) public virtual override {
    require(msg.sender == admin);
    admin = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }

  function transfer(address to, uint256 tokenId) external {
    require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
    _transfer(msg.sender, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
    supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
  }

  function approve(address spender, uint256 tokenId) external {
    address owner_ = ownerOf[tokenId];
    require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
    getApproved[tokenId] = spender;
    emit Approval(owner_, spender, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    isApprovedForAll[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(
      msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
      "NOT_APPROVED"
    );
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0) {
      (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from, tokenId, data));
      bytes4 selector = abi.decode(returned, (bytes4));
      require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf[tokenId] == from);
    _beforeTokenTransfer(from, to, tokenId);

    balanceOf[from]--;
    balanceOf[to]++;

    delete getApproved[tokenId];

    ownerOf[tokenId] = to;
    emit Transfer(msg.sender, to, tokenId);
    _afterTokenTransfer(from, to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

    unchecked {
      balanceOf[to]++;
    }

    ownerOf[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner_ = ownerOf[tokenId];

    require(owner_ != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner_, address(0), tokenId);

    balanceOf[owner_]--;

    delete ownerOf[tokenId];

    emit Transfer(owner_, address(0), tokenId);
    _afterTokenTransfer(owner_, address(0), tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}