// SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error WrongEtherAmount();
error WithdrawalFailed();
error ArrayLengthMismatch();

contract TheMysticEmporium is Ownable {
  struct Item {
    uint256 id;
    uint256 price;
  }

  mapping(uint256 => Item) public itemsForSale;

  event ItemsPurchased(address buyer, uint256[] itemIds, uint256[] quantities);

  constructor(address deployer) {
    _transferOwnership(deployer);
  }

  function buyItems(
    uint256[] calldata ids,
    uint256[] calldata quantities
  ) external payable {
    if (ids.length != quantities.length) revert ArrayLengthMismatch();

    uint256 totalCost;
    uint256 len = ids.length;

    for (uint256 i = 0; i < len; ) {
      totalCost += itemsForSale[ids[i]].price * quantities[i];

      unchecked {
        ++i;
      }
    }

    if (msg.value != totalCost) revert WrongEtherAmount();

    emit ItemsPurchased(msg.sender, ids, quantities);
  }

  function addItem(uint256 id, uint256 price) external onlyOwner {
    itemsForSale[id] = Item(id, price);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");

    if (!success) {
      revert WithdrawalFailed();
    }
  }
}