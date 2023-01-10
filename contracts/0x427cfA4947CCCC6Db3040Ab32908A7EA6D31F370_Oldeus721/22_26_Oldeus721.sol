// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {UpdatableOperatorFilterer} from 'operator-filter-registry/src/UpdatableOperatorFilterer.sol';
import {Oldeus1155} from './Oldeus1155.sol';  
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract Oldeus721 is ERC721A, Ownable, ReentrancyGuard, UpdatableOperatorFilterer {
  address public originContract;
  bool public mintOpen;
  string public baseUri;

  constructor(
    string memory name_,
    string memory symbol_,
    address originContract_,
    string memory baseUri_,
    address registry_,
    address subscription_
  ) ERC721A(name_, symbol_) UpdatableOperatorFilterer(registry_, subscription_, true) {
    originContract = originContract_;
    baseUri = baseUri_;
  }

  function mint(uint256[] calldata tokenIds) external nonReentrant {
    require(tokenIds.length > 0, 'mint: must mint something');
    require(mintOpen, 'mint: not open');

    Oldeus1155(originContract).burnMint(msg.sender, tokenIds);

    _mint(msg.sender, tokenIds.length);
  }

  function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
    return Ownable.owner();
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) nonReentrant {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) nonReentrant {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setMintOpen(bool open) public onlyOwner {
    mintOpen = open;
  }

  function setBaseUri(string calldata baseUri_) public onlyOwner {
    baseUri = baseUri_;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUri;
  }
}