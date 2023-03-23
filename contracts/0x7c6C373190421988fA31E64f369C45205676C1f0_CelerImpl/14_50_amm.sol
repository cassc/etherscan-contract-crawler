// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title HopAMM
 * @notice Interface to handle the token bridging to L2 chains.
 */
interface HopAMM {
    /**
     * @notice To send funds L2->L1 or L2->L2, call the swapAndSend on the L2 AMM Wrapper contract
     * @param chainId chainId of the L2 contract
     * @param recipient receiver address
     * @param amount amount is the amount the user wants to send plus the Bonder fee
     * @param bonderFee fees
     * @param amountOutMin minimum amount
     * @param deadline deadline for bridging
     * @param destinationAmountOutMin minimum amount expected to be bridged on L2
     * @param destinationDeadline destination time before which token is to be bridged on L2
     */
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}