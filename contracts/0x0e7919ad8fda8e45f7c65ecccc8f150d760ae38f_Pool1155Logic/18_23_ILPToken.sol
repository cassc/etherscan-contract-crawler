// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title ILPToken
 * @author Souq.Finance
 * @notice Defines the interface of the LP token of 1155 MMEs
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */

interface ILPToken {
    /**
     * @dev Mints LP tokens to the provided address. Can only be called by the pool.
     * @param to the address to mint the tokens to
     * @param amount the amount to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns LP tokens from the provided address. Can only be called by the pool.
     * @param from the address to burn from
     * @param amount the amount to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Unpauses all token transfers. Can only be called by the pool.
     */
    function unpause() external;

    /**
     * @dev Pauses all token transfers. Can only be called by the pool.
     */
    function pause() external;

    /**
     * @dev Check if the LP Token is paused
     * @return bool true=paused
     */
    function checkPaused() external view returns (bool);

    /**
     * @dev Returns the balance of LP tokens for the provided address.
     * @param account The account to check balance of
     * @return uint256 The amount of LP Tokens owned
     */
    function getBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Approves a specific amount of a token for the pool.
     * @param token The token address to approve
     * @param amount The amount of tokens to approve
     */
    function setApproval20(address token, uint256 amount) external;

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     */
    function RescueTokens(address token, uint256 amount, address receiver) external;

    /**
     * @dev Function to get the the total LP tokens
     * @return uint256 The total number of LP tokens in circulation
     */
    function getTotal() external view returns (uint256);
}