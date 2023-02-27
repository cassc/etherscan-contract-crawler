// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../structs.sol';

library InventoryLibrary {
    function getItemIds(Inventory storage self) public view returns (bytes32[] memory) {
        InventoryItem[] storage items = self.items;
        bytes32[] memory ids = new bytes32[](items.length);
        for (uint256 i; i < items.length; i++) {
            ids[i] = items[i].id;
        }
        return ids;
    }

    function getItem(Inventory storage self, bytes32 tokenId) public view returns (InventoryItem memory) {
        require(self.items.length > 0, 'InventoryLibrary: Inventory is empty');
        // idx can be 0, when no tokenId found in the mapping
        InventoryItem storage item = self.items[self.index[tokenId]];
        // if ids do not match, tokenId wasn't found/out of bounds
        require(item.id == tokenId, 'InventoryLibrary: Token not found for this ID');

        return item;
    }

    function totalItemsAmount(Inventory storage self) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            total += self.items[i].supply;
        }
        return total;
    }

    function totalItemsSold(Inventory storage self) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            total += self.items[i].sold;
        }
        return total;
    }

    // In currency
    function totalPlannedRaise(Inventory storage self) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            InventoryItem memory item = self.items[i];
            total += item.price * item.supply;
        }
        return total;
    }

    function totalRaised(Inventory storage self) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            total += self.items[i].raised;
        }
        return total;
    }

    function getPurchaseValue(
        Inventory storage self,
        bytes32 id,
        uint256 amount
    ) public view returns (uint256) {
        InventoryItem memory item = getItem(self, id);

        return item.price * amount;
    }

    function createOrUpdateInventoryItem(
        Inventory storage self,
        bytes32 id,
        uint256 supply,
        uint256 price,
        uint256 limit
    ) external returns (InventoryItem memory) {
        InventoryItem memory item;

        uint256 lastIdx = self.items.length;
        if (lastIdx == 0) {
            item = InventoryItem(id, supply, price, limit, 0, 0);
            self.items.push(item);
            self.index[id] = lastIdx;

            return item;
        }

        uint256 index = self.index[id];
        item = self.items[index];
        if (item.id == id) {
            item.supply = supply;
            item.price = price;
            item.limit = limit;
            self.items[index] = item;
        } else {
            // Not found, defaulted to 0 idx
            item = InventoryItem(id, supply, price, limit, 0, 0);
            self.items.push(item);
            self.index[id] = lastIdx;
        }

        return item;
    }

    function deleteItem(Inventory storage self, bytes32 id) external returns (bool) {
        InventoryItem[] storage items = self.items;

        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].id == id) {
                for (uint256 j = i; j < items.length - 1; j++) {
                    items[j] = items[j + 1];
                }
                items.pop();

                return true;
            }
        }

        return false;
    }
}