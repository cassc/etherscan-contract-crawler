// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    /**
     * @notice Queries the Party ERC-20 token name
     * @return Token name metadata
     */
    function name() external view returns (string memory);

    /**
     * @notice Queries the Party ERC-20 token symbol
     * @return Token symbol metadata
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Queries the Party ERC-20 token decimals
     * @return Token decimals metadata
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice Queries the Party ERC-20 total minted supply
     * @return Token total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Queries the Party ERC-20 balance of a given account
     * @param account Address
     * @return Token balance of a given ccount
     */
    function balanceOf(address account) external view returns (uint256);
}