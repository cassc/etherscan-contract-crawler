//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";

contract POTA is ERC721A, Ownable, ReentrancyGuard, AccessControl, DefaultOperatorFilterer {
  using ECDSA for bytes32;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bool public ENABLED = false;
  string public tokenUriBase;
  uint256 public maxSupply = 140;

  constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setEnabled(bool _state) external onlyOwner {
    ENABLED = _state;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
    return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
  }

  function setTokenURI(string memory _tokenUriBase) external onlyOwner {
    tokenUriBase = _tokenUriBase;
  }

  function setMaxSupply(uint256 _supply) external onlyOwner {
    maxSupply = _supply;
  }

  function mintToWallet(address walletAddress, uint256 quantity) external onlyOwner {
    require(ENABLED, "minting is not enabled.");
    require(totalSupply() + quantity <= maxSupply, "mint request exceeds supply limit.");
    _safeMint(walletAddress, quantity);
  }

  function mint(address walletAddress, uint256 quantity) external onlyRole(MINTER_ROLE) {
    require(ENABLED, "minting is not enabled.");
    _safeMint(walletAddress, quantity);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}