// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import './WithInventory.sol';

abstract contract WithSaleData is WithInventory {
    // User -> tokenType -> amount
    mapping(address => mapping(bytes32 => uint256)) public balances;
    mapping(address => uint256) public contributed;

    uint256 public participants;
    uint256 public firstPurchaseBlockN;
    uint256 public lastPurchaseBlockN;

    function balanceOf(address account) external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < inventory.items.length; i++) {
            InventoryItem storage item = inventory.items[i];
            total += balances[account][item.id];
        }

        return total;
    }

    function balanceAggregatedOf(address account) external view returns (bytes32[] memory, uint256[] memory) {
        bytes32[] memory ids = new bytes32[](inventory.items.length);
        uint256[] memory amounts = new uint256[](inventory.items.length);

        for (uint256 i = 0; i < inventory.items.length; i++) {
            bytes32 id = inventory.items[i].id;
            ids[i] = id;
            amounts[i] = balances[account][id];
        }

        return (ids, amounts);
    }

    function balanceOf(address account, bytes32 tokenId) public view returns (uint256) {
        return balances[account][tokenId];
    }
}