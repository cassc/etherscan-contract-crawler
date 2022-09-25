// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import {Recipe} from "../contracts/RecipeContainer.sol";

interface IRecipeContainer {
    function getRecipe(uint recipeId) external view returns (Recipe memory);
    function storeRecipe(
        string memory _name,
        bytes[] memory _callData,
        bytes32[] memory _subData,
        bytes4[] memory _actionIds,
        uint8[][] memory _paramMapping
    ) 
        external 
        returns (uint);
}