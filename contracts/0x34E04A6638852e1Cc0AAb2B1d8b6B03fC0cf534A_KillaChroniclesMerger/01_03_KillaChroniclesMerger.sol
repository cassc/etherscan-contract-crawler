// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

struct Recipe {
    uint256 result;
    uint256[] ingredients;
    uint256[] quantities;
}

interface IKillaChronicles {
    function mint(
        uint256 tokenId,
        address recipient,
        uint256 qty
    ) external;

    function burn(
        uint256 tokenId,
        address owner,
        uint256 qty
    ) external;
}

interface IKillaChroniclesSBT {
    function increaseBalance(
        address recipient,
        uint256 volumeId,
        uint256 qty
    ) external;
}

/* ----------
    Contract
   ---------- */

contract KillaChroniclesMerger is Ownable {
    IKillaChronicles immutable chroniclesContract;
    IKillaChroniclesSBT sbtContract;

    uint256 recipeCount;
    mapping(uint256 => Recipe) recipes;

    constructor(address chronicles, address sbt) {
        chroniclesContract = IKillaChronicles(chronicles);
        sbtContract = IKillaChroniclesSBT(sbt);
    }

    error NonExistentMergeRecipe();

    /* ---------
        Merging
       --------- */

    /// @notice Merge chronicles
    function merge(uint256 id, uint256 qty) external {
        Recipe storage recipe = recipes[id];
        if (recipe.result == 0) revert NonExistentMergeRecipe();
        for (uint256 i = 0; i < recipe.ingredients.length; i++) {
            chroniclesContract.burn(
                recipe.ingredients[i],
                msg.sender,
                qty * recipe.quantities[i]
            );
            sbtContract.increaseBalance(
                msg.sender,
                recipe.ingredients[i],
                qty * recipe.quantities[i]
            );
        }
        chroniclesContract.mint(recipe.result, msg.sender, qty);
    }

    /* -------
        Admin
       ------- */

    /// @notice Configure a merge recipe
    function configureRecipe(uint256 id, Recipe calldata recipe)
        external
        onlyOwner
    {
        recipes[id] = recipe;
    }

    /// @notice Remove a merge recipe
    function removeRecipe(uint256 id) external onlyOwner {
        delete recipes[id];
    }

    /// @notice Changes the address of the SBT contract
    function setSBTContract(address sbt) external onlyOwner {
        sbtContract = IKillaChroniclesSBT(sbt);
    }
}