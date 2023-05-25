//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Controllable} from "./Controllable.sol";

error ERC1155_Error404();
error ERC1155_BurnAmountExceedSupply();
error ERC1155_Paused();
error ERC1155_SupplyIsNotZero();
error ERC1155_NotOwnerOrController();

/// @notice Items struct
struct Item {
  string uri;
  uint64 id;
  uint64 supply;
  bool isPaused;
}

abstract contract ERC1155Factory is ERC1155, Controllable {
  /// @notice token tracker
  string public name;
  string public symbol;

  Item[] public items;

  constructor(string memory name_, string memory symbol_) ERC1155("") {
    name = name_;
    symbol = symbol_;
  }

  modifier onlyOwnerOrController() {
    if (!(owner() == _msgSender() || isController(_msgSender()))) revert ERC1155_NotOwnerOrController();
    _;
  }

  /* -------------------------------------------------------------------------- */
  /*                                Items Admin                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice add new item
  function addItem(string memory itemUri, bool isPaused) external onlyOwner {
    Item memory item = Item(itemUri, uint64(items.length), 0, isPaused);
    items.push(item);
  }

  /// @notice edit item.uri
  function editItem_uri(uint256 id, string memory newUri) external onlyOwner {
    if (!exists(id)) revert ERC1155_Error404();
    items[id].uri = newUri;
    emit URI(newUri, id);
  }

  /// @notice edit item.isPaused
  function editItem_isPaused(uint256 id, bool _isPaused) external onlyOwner {
    if (!exists(id)) revert ERC1155_Error404();
    items[id].isPaused = _isPaused;
  }

  /// @notice remove last item if supply != 0
  function removeLastItem() external onlyOwner {
    if (items.length == 0) revert ERC1155_Error404();
    if (items[items.length - 1].supply > 0) revert ERC1155_SupplyIsNotZero();
    items.pop();
  }

  /// @notice pause or unpause all items
  function paused(bool _isPaused) external onlyOwner {
    for (uint256 id; id < items.length; id++) {
      items[id].isPaused = _isPaused;
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                Supply & uri                                */
  /* -------------------------------------------------------------------------- */

  /// @notice check if an item exists by id.
  function exists(uint256 id) public view returns (bool) {
    return id < items.length;
  }

  /// @notice item's uri by id
  function uri(uint256 id) public view override returns (string memory) {
    if (!exists(id)) revert ERC1155_Error404();
    return items[id].uri;
  }

  /// @notice item's supply by id.
  function totalSupply(uint256 id) public view returns (uint256) {
    if (!exists(id)) revert ERC1155_Error404();
    return items[id].supply;
  }

  /* -------------------------------------------------------------------------- */
  /*                                Items getters                               */
  /* -------------------------------------------------------------------------- */

  /// @notice return item by id
  function getItem(uint256 id) external view returns (Item memory) {
    return items[id];
  }

  /// @notice return all items
  function getItems() external view returns (Item[] memory) {
    return items;
  }

  /* -------------------------------------------------------------------------- */
  /*                           Internal Helpers                                 */
  /* -------------------------------------------------------------------------- */

  function _mint(
    address to,
    uint256 id,
    uint256 amount
  ) internal {
    if (!exists(id)) revert ERC1155_Error404();
    super._mint(to, id, amount, bytes(""));
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal {
    for (uint256 i; i < ids.length; ++i) {
      uint256 id = ids[i];
      if (!exists(id)) revert ERC1155_Error404();
    }

    super._mintBatch(to, ids, amounts, bytes(""));
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual override {
    if (!exists(id)) revert ERC1155_Error404();

    Item storage item = items[id];
    if (amount > item.supply) revert ERC1155_BurnAmountExceedSupply();

    super._burn(from, id, amount);
  }

  /* -------------------------------------------------------------------------- */
  /*                         Supply & Permission                                */
  /* -------------------------------------------------------------------------- */

  /**
   * @dev See {IERC1155-isApprovedForAll}. Allow controllers
   */
  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return isController(operator) || super.isApprovedForAll(account, operator);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    // mint -> increase supply
    if (from == address(0)) {
      for (uint256 i; i < ids.length; ++i) {
        Item storage item = items[ids[i]];
        item.supply += uint64(amounts[i]);
      }
    }

    // burn -> decrease supply
    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        Item storage item = items[ids[i]];
        uint64 amount = uint64(amounts[i]);
        if (amount > item.supply) revert ERC1155_BurnAmountExceedSupply();
        unchecked {
          item.supply -= uint64(amount);
        }
      }
    }

    // transfer
    if (to != address(0) && from != address(0)) {
      for (uint256 i; i < ids.length; ++i) {
        Item storage item = items[ids[i]];
        if (item.isPaused) revert ERC1155_Paused();
      }
    }
  }
}