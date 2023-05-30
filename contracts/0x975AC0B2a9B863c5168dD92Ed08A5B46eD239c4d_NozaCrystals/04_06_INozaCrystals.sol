// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/**
 * @title Noza Crystals Interface
 * @author Roope R. Pajunen
 */
interface INozaCrystals {
    /**
     * @dev This error is thrown when the mint function is called in a way that would increase the total supply of
     * tokens beyond the MAX_SUPPLY.
     */
    error MaxSupplyReached();

    /**
     * @dev The maximum supply of tokens that can be minted. This is a constant value and cannot be changed after
     * deployment.
     *
     * @notice Once the total supply of tokens reaches this number, no more tokens can be minted.
     */
    function MAX_SUPPLY() external returns (uint256);

    /**
     * @dev External function to set the base URI for all tokens. It can be called only by the contract owner.
     *
     * @param baseURI The new base URI for the tokens.
     *
     * Requirements:
     * - The caller must be the owner.
     *
     * @notice This function does not emit any events.
     */
    function setBaseURI(string calldata baseURI) external;

    /**
     * @dev This function allows the contract's owner to mint a specific quantity of tokens and distribute them among an
     * array of recipient addresses. It ensures that the total minted supply cannot exceed the maximum supply defined in
     * the contract. This function can only be called by the owner of the contract.
     *
     * @param recipients An array of addresses to which the new tokens will be assigned.
     * @param quantity The quantity of tokens that will be minted for each recipient.
     *
     * Requirements:
     * - The caller must be the owner.
     * - The total minted supply after this operation must be less or equal to the MAX_SUPPLY.
     *
     * Emits a {Transfer} event for each mint operation.
     *
     * @notice If the total minted supply exceeds the maximum supply after this operation, the transaction will revert.
     */
    function mint(address[] calldata recipients, uint256 quantity) external;
}