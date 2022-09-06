// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

interface IERC20Query {
    /**
     * Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}