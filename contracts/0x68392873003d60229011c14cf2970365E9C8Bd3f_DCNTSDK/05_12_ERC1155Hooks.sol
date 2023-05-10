// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'solmate/src/tokens/ERC1155.sol';

abstract contract ERC1155Hooks is ERC1155 {
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) public virtual override {
    _beforeTokenTransfers(from, to, _asSingletonArray(id), _asSingletonArray(amount));
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual override {
    _beforeTokenTransfers(from, to, ids, amounts);
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    _beforeTokenTransfers(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));
    super._mint(to, id, amount, data);
  }

  function _batchMint(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    _beforeTokenTransfers(address(0), to, ids, amounts);
    super._batchMint(to, ids, amounts, data);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual override {
    _beforeTokenTransfers(msg.sender, address(0), _asSingletonArray(id), _asSingletonArray(amount));
    super._burn(from, id, amount);
  }

  function _batchBurn(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual override {
    _beforeTokenTransfers(msg.sender, address(0), ids, amounts);
    super._batchBurn(from, ids, amounts);
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;
    return array;
  }
}