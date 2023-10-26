// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IOptionToken interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for managing option token contracts
 */
interface IOptionToken {
    /**
     * @notice Get the total supply of option tokens
     * @dev Returns the total supply of option tokens
     * @return The total supply of option tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get the balance of the specified account
     * @dev Returns the balance of the specified account
     * @param account The account to retrieve the balance for
     * @return The balance of the specified account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Mint new option tokens and assign them to the specified account
     * @dev Mints new option tokens and assigns them to the specified account
     * @param _account The account to assign the new tokens to
     * @param _amount The amount of new tokens to mint
     */
    function mintFor(address _account, uint256 _amount) external;

    /**
     * @notice Burn the specified amount of option tokens
     * @dev Burns the specified amount of option tokens from the caller's account
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burn the specified amount of option tokens from the specified account
     * @dev Burns the specified amount of option tokens from the specified account
     * @param account The account to burn the tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @notice Update the symbol of the option token
     * @dev Updates the symbol of the option token to the specified value
     * @param _new_symbol The new symbol of the option token
     */
    function updateSymbol(string memory _new_symbol) external;

    /**
     * @notice Activate the option token with the specified parameters
     * @dev Activates the option token with the specified option ID, name, and symbol
     * FIXME: should "_optionID" below just be "optionID" if it's set when the option is created
     * @param _optionID The ID of the option contract
     * @param _new_name The new name of the option token
     * @param _new_symbol The new symbol of the option token
     */
    function activeInit(uint256 _optionID, string memory _new_name, string memory _new_symbol) external;
}