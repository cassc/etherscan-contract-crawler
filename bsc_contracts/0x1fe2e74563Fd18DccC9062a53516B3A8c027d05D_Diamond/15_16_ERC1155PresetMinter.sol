// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import './ERC1155SupplyWithAll.sol';

contract ERC1155PresetMinter is Ownable, ERC1155Burnable, ERC1155SupplyWithAll {
  constructor(string memory uri) ERC1155(uri) {}

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual onlyOwner {
    _mint(to, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155SupplyWithAll) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}