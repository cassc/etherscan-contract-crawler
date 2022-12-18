//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PegSwap {
    /**
     * @notice deposits tokens from the target of a swap pair but does not return
     * any. WARNING: Liquidity added through this method is only retrievable by
     * the owner of the contract.
     * @param amount count of liquidity being added
     * @param source the token that can be swapped for what is being deposited
     * @param target the token that can is being deposited for swapping
     */
    function addLiquidity(
        uint256 amount,
        address source,
        address target
    ) external;

    /**
     * @notice withdraws tokens from the target of a swap pair.
     * @dev Only callable by owner
     * @param amount count of liquidity being removed
     * @param source the token that can be swapped for what is being removed
     * @param target the token that can is being withdrawn from swapping
     */
    function removeLiquidity(
        uint256 amount,
        address source,
        address target
    ) external;

    /**
     * @notice exchanges the source token for target token
     * @param amount count of tokens being swapped
     * @param source the token that is being given
     * @param target the token that is being taken
     */
    function swap(
        uint256 amount,
        address source,
        address target
    ) external;

    /**
     * @notice send funds that were accidentally transferred back to the owner. This
     * allows rescuing of funds, and poses no additional risk as the owner could
     * already withdraw any funds intended to be swapped. WARNING: If not called
     * correctly this method can throw off the swappable token balances, but that
     * can be recovered from by transferring the discrepancy back to the swap.
     * @dev Only callable by owner
     * @param amount count of tokens being moved
     * @param target the token that is being moved
     */
    function recoverStuckTokens(uint256 amount, address target) external;

    /**
     * @notice swap tokens in one transaction if the sending token supports ERC677
     * @param sender address that initially initiated the call to the source token
     * @param amount count of tokens sent for the swap
     * @param targetData address of target token encoded as a bytes array
     */
    function onTokenTransfer(
        address sender,
        uint256 amount,
        bytes calldata targetData
    ) external;
}