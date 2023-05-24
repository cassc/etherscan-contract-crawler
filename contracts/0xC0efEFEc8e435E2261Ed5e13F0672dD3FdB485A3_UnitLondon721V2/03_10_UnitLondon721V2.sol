// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SimpleERC721.sol";
import "./utils/RoyaltySupportV2.sol";

contract UnitLondon721V2 is SimpleERC721, RoyaltySupportV2 {
  bool public initialized;

  mapping(uint256 => string) public _tokenURI; // 2023.05.22 - Deprecated
  uint256 public totalSupply;
  address _marketplace;

  function initialize(string calldata _name, string calldata _symbol) external onlyOwner {
    require(!initialized);
    initialized = true;

    name = _name;
    symbol = _symbol;
    _marketplace = msg.sender;

    super.__DefaultOperatorFilterer_init();
    super.transferOwnership(msg.sender);
  }

  function marketplace() public view virtual override returns (IMarketplaceV2) {
    return IMarketplaceV2(_marketplace);
  }

  function mint(
    uint256 tokenId,
    // string calldata metadata, // 2023.05.22 - Deprecated
    address user
  ) external {
    require(msg.sender == _marketplace, "Invalid minter");
    _mint(user, tokenId);
    // _tokenURI[tokenId] = metadata;
    totalSupply = totalSupply + 1;
  }

  function tokenURI(uint256 tokenId) external view override returns(string memory) {
    return marketplace().tokenURI(address(this), tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}