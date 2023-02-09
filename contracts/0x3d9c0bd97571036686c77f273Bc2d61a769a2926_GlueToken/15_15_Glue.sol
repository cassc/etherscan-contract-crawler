// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Supply, ERC1155 } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { DefaultOperatorFilterer } from "../../royalty/DefaultOperatorFilterer.sol";

contract GlueToken is Ownable, ERC1155Burnable, ERC1155Supply, DefaultOperatorFilterer {
  struct TokenInfo {
    string uri;
  }

  mapping(uint64 => TokenInfo) public tokens;

  constructor() ERC1155("") {
    tokens[0].uri = "ipfs://Qmc2E4qkRRQ5VyX1dxqg15aqnh1sYC5uzFBBoS6EtP5vE2";
  }

  /* View */
  function uri(uint256 _id) public view virtual override returns (string memory) {
    require(exists(_id), "Non exist token");
    return tokens[uint64(_id)].uri;
  }

  // verified
  function mintTokens(
    uint64[] memory _tokenIds,
    address[] memory _accounts,
    uint256[] memory _amounts
  ) external onlyOwner {
    require(_tokenIds.length == _accounts.length, "Invalid input");
    require(_tokenIds.length == _amounts.length, "Invalid input");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _mint(_accounts[i], _tokenIds[i], _amounts[i], "");
    }
  }

  /* Admin */
  // verified
  function setTokensUri(uint64[] calldata _tokenIds, string[] calldata _uri) external onlyOwner {
    require(_tokenIds.length == _uri.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].uri = _uri[i];
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155Supply, ERC1155) {
    if (from == address(0) || to == address(0)) {
      return super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    revert("This asset is non-transferable");
  }

  /* Royalty */
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