//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/AcceptedToken.sol";
import "../interfaces/equipment/IEquipmentCrafting.sol";
import "../interfaces/material/IMaterial.sol";

contract EquipmentCrafting is IEquipmentCrafting, AcceptedToken {
    using EnumerableSet for EnumerableSet.UintSet;

    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IMaterial public immutable materialContract;

    ItemRecipe[] private _itemRecipes; // Containing all item recipes available.
    EnumerableSet.UintSet private _enhancedMaterialIds; // Set of enhanced material ids.
    mapping(uint => uint) private _enhancedMaterialRates; // Mapping from enhancedMaterialId to its bonus rate for crafting.

    /**
     * @param _materialContract: for burning crafting materials.
     * @param _tokenContract: for collecting crafting fee paid in tokens.
     */
    constructor(
        IMaterial _materialContract,
        IERC20 _tokenContract
    ) AcceptedToken(_tokenContract) {
        materialContract = _materialContract;
    }

    function addEnhancedMaterials(uint[] calldata materialIds, uint[] calldata increasedRates) external onlyOwner {
        require(materialIds.length > 0 && materialIds.length == increasedRates.length);

        for (uint i = 0; i < materialIds.length; i++) {
            require(increasedRates[i] > 0 && increasedRates[i] <= 100);

            _enhancedMaterialIds.add(materialIds[i]);
            _enhancedMaterialRates[materialIds[i]] = increasedRates[i];
        }
    }

    function removeEnhancedMaterials(uint[] calldata enhancedMaterialIds) external onlyOwner {
        for (uint i = 0; i < enhancedMaterialIds.length; i++) {
            _enhancedMaterialIds.remove(enhancedMaterialIds[i]);
            _enhancedMaterialRates[enhancedMaterialIds[i]] = 0;
        }
    }

    /**
     * @notice id = 0 to create a new recipe.
     */
    function setItemRecipe(
        uint id,
        uint tokenFee,
        uint successRate,
        uint maxRarityImproved,
        uint point,
        uint[] memory itemIds,
        uint[] memory itemRates,
        uint[] memory requiredMaterialIds,
        uint[] memory requiredMaterialAmounts
    ) public onlyOwner {
        require(maxRarityImproved <= itemRates[0]);
        require(
            successRate > 0 && successRate <= 100 &&
            itemIds.length > 0 && itemIds.length == itemRates.length &&
            requiredMaterialIds.length > 0 && requiredMaterialIds.length == requiredMaterialAmounts.length
        );

        ItemRecipe memory itemRecipe = ItemRecipe(
            id, tokenFee, successRate, maxRarityImproved, point,
            itemIds, itemRates, requiredMaterialIds, requiredMaterialAmounts
        );

        uint itemRecipeId = id;

        if (itemRecipeId > 0) {
            _itemRecipes[itemRecipeId] = itemRecipe;
        } else {
            _itemRecipes.push(itemRecipe);
            itemRecipeId = _itemRecipes.length - 1;
        }

        emit ItemRecipeSet(itemRecipeId, itemRecipe);
    }

    function setItemRecipes(ItemRecipe[] calldata itemRecipes) external onlyOwner {
        for (uint i = 0; i < itemRecipes.length; i++) {
            ItemRecipe memory itemRecipe = itemRecipes[i];
            setItemRecipe(
                itemRecipe.id,
                itemRecipe.tokenFee,
                itemRecipe.successRate,
                itemRecipe.maxRarityImproved,
                itemRecipe.point,
                itemRecipe.itemIds,
                itemRecipe.itemRates,
                itemRecipe.requiredMaterialIds,
                itemRecipe.requiredMaterialAmounts
            );
        }
    }

    /**
     * @dev See {IEquipmentCrafting-craftItem}.
     */
    function craftItem(uint itemRecipeId, uint amount, uint enhanceMaterialId) external override {
        address account = msg.sender;
        ItemRecipe memory itemRecipe = _itemRecipes[itemRecipeId];

        require(amount > 0);

        // Collect token fee for the crafting process.
        if (itemRecipe.tokenFee > 0) {
            acceptedToken.transferFrom(account, owner(), itemRecipe.tokenFee * amount);
        }

        // Burn all required materials for the crafting process.
        for (uint i = 0; i < itemRecipe.requiredMaterialIds.length; i++) {
            materialContract.burn(
                account,
                itemRecipe.requiredMaterialIds[i],
                itemRecipe.requiredMaterialAmounts[i] * amount
            );
        }

        // Calculate increased rate for crafting based on given enhanced material.
        uint increasedRate = 0;
        if (enhanceMaterialId != 0) {
            materialContract.burn(account, enhanceMaterialId, amount);
            increasedRate = _enhancedMaterialRates[enhanceMaterialId];
        }

        emit ItemCrafted(itemRecipeId, amount, account, increasedRate);
    }

    function getItemRecipe(uint itemRecipeId) external view returns (
        uint tokenFee,
        uint successRate,
        uint maxRarityImproved,
        uint point,
        uint[] memory itemIds,
        uint[] memory itemRates,
        uint[] memory requiredMaterialIds,
        uint[] memory requiredMaterialAmounts
    ) {
        ItemRecipe memory itemRecipe = _itemRecipes[itemRecipeId];

        tokenFee = itemRecipe.tokenFee;
        successRate = itemRecipe.successRate;
        maxRarityImproved = itemRecipe.maxRarityImproved;
        point = itemRecipe.point;
        itemIds = itemRecipe.itemIds;
        itemRates = itemRecipe.itemRates;
        requiredMaterialIds = itemRecipe.requiredMaterialIds;
        requiredMaterialAmounts = itemRecipe.requiredMaterialAmounts;
    }

    function getAllEnhancedMaterialIds() external view returns (uint[] memory ids, uint[] memory rates) {
        uint materialCount = _enhancedMaterialIds.length();
        ids = new uint[](materialCount);
        rates = new uint[](materialCount);

        for (uint i = 0; i < materialCount; i++) {
            ids[i] = _enhancedMaterialIds.at(i);
            rates[i] = _enhancedMaterialRates[ids[i]];
        }
    }
}