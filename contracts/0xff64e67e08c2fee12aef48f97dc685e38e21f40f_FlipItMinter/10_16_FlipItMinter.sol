// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { Random } from "./libraries/Random.sol";

import { IERC721AMintable } from "./interfaces/IERC721AMintable.sol";
import { IERC1155Mintable } from "./interfaces/IERC1155Mintable.sol";

import { IFlipItMinter } from "./IFlipItMinter.sol";

/**
 *  @title FlipIt nft minter
 *
 *  @notice An implementation of the smart contract for minting nfts in the FlipIt ecosystem.
 */
contract FlipItMinter is IFlipItMinter, AccessControl {
    /// @notice A struct containing the ingredient configuration.
    /// @param name Name of the ingredient.
    /// @param tokenId Id of the related token.
    /// @param minMintChanceThreshold Minimum value of the mint chance.
    /// @param maxMintChanceThreshold Maximum value of the mint chance.
    struct Ingredient {
        string name;
        uint256 tokenId;
        uint256 minMintChanceThreshold;
        uint256 maxMintChanceThreshold;
    }

    //-------------------------------------------------------------------------
    // Constants & Immutables

    bytes32 internal constant AUTHORIZED_TO_MINT_ROLE = keccak256("AUTHORIZED_TO_MINT_ROLE");

    uint256 internal constant MIN_MINT_CHANCE_THRESHOLD = 1;
    uint256 internal constant MAX_MINT_CHANCE_THRESHOLD = 100;

    /// @notice Address to the external smart contract that mints nfts.
    IERC721AMintable public immutable burgerIssuer;

    /// @notice Address to the external smart contract that mints nfts.
    IERC1155Mintable internal immutable ingredientIssuer;

    //-------------------------------------------------------------------------
    // Storage

    Ingredient[] internal _ingredients;

    //-------------------------------------------------------------------------
    // Errors

    /// @notice The given values are outside the defined range.
    /// @param min Minimum value of the mint chance.
    /// @param max Maximum value of the mint chance.
    error InvalidMintChance(uint256 min, uint256 max);

    /// @notice Insufficient balance of token.
    /// @param tokenId Id of the missing token.
    /// @param amount Amount of the missing token.
    error InsufficientBalanceOfToken(uint256 tokenId, uint256 amount);

    /// @notice Contract reference is `address(0)`.
    error UnacceptableReference();

    //-------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param burgerIssuer_ Address to the external smart contract that mints nfts.
    /// @param ingredientIssuer_ Address to the external smart contract that mints nfts.
    constructor(IERC721AMintable burgerIssuer_, IERC1155Mintable ingredientIssuer_) {
        if (address(burgerIssuer_) == address(0) || address(ingredientIssuer_) == address(0)) revert UnacceptableReference();

        burgerIssuer = burgerIssuer_;
        ingredientIssuer = ingredientIssuer_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @inheritdoc IFlipItMinter
    /// @dev Throws error if account has an insufficient token balance.
    function mintBurger(address recipient, uint256 amount) external onlyRole(AUTHORIZED_TO_MINT_ROLE) returns (uint256[] memory) {
        uint256 numberOfIngredients = _ingredients.length;

        /// Prepares arrays to store token ids and amounts to mint.
        uint256[] memory ids = new uint256[](numberOfIngredients);
        uint256[] memory amounts = new uint256[](numberOfIngredients);

        for (uint i = 0; i < numberOfIngredients; i++) {
            uint256 tokenId = _ingredients[i].tokenId;

            if (ingredientIssuer.balanceOf(recipient, tokenId) < amount) revert InsufficientBalanceOfToken(tokenId, amount);

            ids[i] = tokenId;
            amounts[i] = amount;
        }

        /// Burns "used" ingredients
        ingredientIssuer.burnBatch(recipient, ids, amounts);

        burgerIssuer.mint(recipient, amount);

        return ids;
    }

    /// @inheritdoc IFlipItMinter
    function mintIngredient(address recipient, uint256 amount) external onlyRole(AUTHORIZED_TO_MINT_ROLE) returns (uint256[] memory) {
        uint256 numberOfIngredients = _ingredients.length;

        /// Stores in a memory variable for gas optimization
        Ingredient[] memory items = _ingredients;

        /// Prepares arrays to store token ids and amounts to mint.
        uint256[] memory ids = new uint256[](numberOfIngredients);
        uint256[] memory amounts = new uint256[](numberOfIngredients);

        for (uint256 i = 0; i < amount; i++) {
            /// Draws a number between 1 and 100.
            uint256 chance = Random.number(i * numberOfIngredients, MIN_MINT_CHANCE_THRESHOLD, MAX_MINT_CHANCE_THRESHOLD, recipient);

            /// Searches for an ingredient - the value of `chance` must be within the ingredient "chance to mint" range.
            for (uint indexOfIngredient = 0; indexOfIngredient < numberOfIngredients; indexOfIngredient++) {
                if (chance < items[indexOfIngredient].minMintChanceThreshold) continue;
                if (chance > items[indexOfIngredient].maxMintChanceThreshold) continue;

                ids[indexOfIngredient] = items[indexOfIngredient].tokenId;
                amounts[indexOfIngredient] += 1;

                break;
            }
        }

        ingredientIssuer.mintBatch(recipient, ids, amounts, "");

        return ids;
    }

    /// @notice Adds new ingredient.
    /// @param name Name of the ingredient.
    /// @param tokenId Id of the nft related to the ingredient.
    /// @param minMintChanceThreshold Minimum value of the chance to be minted.
    /// @param maxMintChanceThreshold Maximum value of the chance to be minted.
    /// @dev Throws error if `minMintChanceThreshold` or `maxMintChanceThreshold` values are out of range (1 - 100).
    function addIngredient(
        string calldata name,
        uint256 tokenId,
        uint256 minMintChanceThreshold,
        uint256 maxMintChanceThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            minMintChanceThreshold < MIN_MINT_CHANCE_THRESHOLD ||
            maxMintChanceThreshold > MAX_MINT_CHANCE_THRESHOLD ||
            minMintChanceThreshold > maxMintChanceThreshold
        ) {
            revert InvalidMintChance(minMintChanceThreshold, maxMintChanceThreshold);
        }

        Ingredient memory ingredient_ = Ingredient({
            name: name,
            tokenId: tokenId,
            minMintChanceThreshold: minMintChanceThreshold,
            maxMintChanceThreshold: maxMintChanceThreshold
        });

        _ingredients.push(ingredient_);
    }

    /// @return Returns the ingredients.
    function ingredients() external view returns (Ingredient[] memory) {
        return _ingredients;
    }
}