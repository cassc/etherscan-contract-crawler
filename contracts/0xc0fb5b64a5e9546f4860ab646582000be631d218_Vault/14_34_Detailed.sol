// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

abstract contract DetailedShare {
    /**
     * @notice A representation of a floating point number.
     * `decimals` is the number of digits before the where the decimal point would be placeds
     */
    struct Number {
        uint256 num;
        uint8 decimals;
    }

    /// @notice The tvl is a dollar amount representing the total value locked in the vault.
    function detailedTVL() external virtual returns (Number memory);

    /**
     * @notice The number of dollars that "one" share is worth.
     * @dev "One" share is always 1 * 10 ^ (decimals). Note that `decimals` refers
     * to the ERC20 property.
     */
    function detailedPrice() external virtual returns (Number memory);

    /**
     * @notice The total supply of the token. The value of Number.num here is the same as `totalSupply()`
     * @dev detailedTVL() / detailedTotalSupply() ==  detailedPrice()
     */
    function detailedTotalSupply() external virtual returns (Number memory);
}