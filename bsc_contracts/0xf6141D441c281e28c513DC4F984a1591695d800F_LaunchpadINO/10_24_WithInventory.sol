// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../sale/Timed.sol';
import '../Adminable.sol';
import './libraries/InventoryLibrary.sol';
import './structs.sol';

abstract contract WithInventory is Adminable {
    using InventoryLibrary for Inventory;

    event InventoryItemUpdated(bytes32 indexed id, uint256 supply, uint256 price, uint256 limit);
    event InventoryItemDeleted(bytes32 indexed id);

    Inventory internal inventory;

    function getInventoryItems() public view returns (InventoryItem[] memory) {
        return inventory.items;
    }

    function getItemIds() public view returns (bytes32[] memory) {
        return inventory.getItemIds();
    }

    function getItem(bytes32 tokenId) public view returns (InventoryItem memory) {
        return inventory.getItem(tokenId);
    }

    function totalItemsAmount() public view returns (uint256) {
        return inventory.totalItemsAmount();
    }

    function totalItemsSold() public view returns (uint256) {
        return inventory.totalItemsSold();
    }

    // In currency
    function totalPlannedRaise() public view returns (uint256) {
        return inventory.totalPlannedRaise();
    }

    function totalRaised() public view returns (uint256) {
        return inventory.totalRaised();
    }

    function getPurchaseValue(bytes32 id, uint256 amount) public view returns (uint256) {
        return inventory.getPurchaseValue(id, amount);
    }

    // Creates or updates items
    function fillInventory(
        bytes32[] calldata ids,
        uint256[] calldata supplies,
        uint256[] calldata prices,
        uint256[] calldata limits
    ) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];

            InventoryItem memory item = inventory.createOrUpdateInventoryItem(id, supplies[i], prices[i], limits[i]);

            emit InventoryItemUpdated(item.id, item.supply, item.price, item.limit);
        }
    }

    function deleteItem(bytes32 id) external onlyOwnerOrAdmin {
        bool deleted = inventory.deleteItem(id);
        if (deleted) {
            emit InventoryItemDeleted(id);
        }
    }
}