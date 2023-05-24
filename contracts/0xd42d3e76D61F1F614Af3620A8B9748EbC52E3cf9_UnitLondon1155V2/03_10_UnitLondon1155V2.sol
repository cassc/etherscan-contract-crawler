// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SimpleERC1155.sol";
import "./utils/RoyaltySupportV2.sol";

contract UnitLondon1155V2 is SimpleERC1155, RoyaltySupportV2 {
  bool public initialized;

  mapping(uint256 => string) public _uri; // 2023.05.22 - Deprecated
  mapping(uint256 => uint256) public totalSupply;
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
    uint256 amount,
    // string calldata metadata, // 2023.05.22 - Deprecated
    address user
  ) external {
    require(msg.sender == _marketplace, "Invalid minter");
    _mint(user, tokenId, amount, "");
    // if (totalSupply[tokenId] == 0) {
    //   uri[tokenId] = metadata;
    // }
    totalSupply[tokenId] = totalSupply[tokenId] + amount;
  }

  function uri(uint256 tokenId) external view override returns(string memory) {
    return marketplace().tokenURI(address(this), tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}