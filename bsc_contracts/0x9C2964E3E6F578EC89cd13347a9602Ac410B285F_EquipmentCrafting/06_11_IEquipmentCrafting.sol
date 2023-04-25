//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEquipmentCrafting {
    struct ItemRecipe {
        uint id;
        uint tokenFee;
        uint successRate;
        uint maxRarityImproved;
        uint point;
        uint[] itemIds;
        uint[] itemRates;
        uint[] requiredMaterialIds;
        uint[] requiredMaterialAmounts;
    }

    struct EnhancedMaterial {
        uint id;
        uint rate;
    }

    event ItemRecipeSet(uint indexed itemRecipeId, ItemRecipe itemRecipe);
    event ItemCrafted(uint indexed itemRecipeId, uint amount, address account, uint increasedRate);

    /**
     * @notice Crafts an item.
     */
    function craftItem(uint itemRecipeId, uint amount, uint enhanceMaterialId) external;
}