//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.9;

/**
 * @title UBI Token
 * @dev Simpler version of Uniswap v2 and v3 protocol interface
 */
interface IUBI {
    /**
     * @dev Calculates the current user accrued balance.
     * @param _human The submission ID.
     * @return The current balance including accrued Universal Basic Income of the user.
     **/
    function balanceOf(address _human) external view returns (uint256);

    /** @dev Approves `_spender` to spend `_amount`.
     *  @param _spender The entity allowed to spend funds.
     *  @param _amount The amount of base units the entity will be allowed to spend.
     */
    function approve(address _spender, uint256 _amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /** @dev Burns `_amount` of tokens and withdraws accrued tokens.
     *  @param _amount The quantity of tokens to burn in base units.
     */
    function burn(uint256 _amount) external;

    /** @dev Increases the `_spender` allowance by `_addedValue`.
     *  @param _spender The entity allowed to spend funds.
     *  @param _addedValue The amount of extra base units the entity will be allowed to spend.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);

    /** @dev Decreases the `_spender` allowance by `_subtractedValue`.
     *  @param _spender The entity whose spending allocation will be reduced.
     *  @param _subtractedValue The reduction of spending allocation in base units.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
}