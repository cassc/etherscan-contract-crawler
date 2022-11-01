//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title  License Token Mint Fee Settler
 * @author ysqi
 * @notice Licens token mint fee management settlement center.
 */
interface IMintFeeSettler {
    /**
     * @notice Triggered when a Derivative contract is traded
     *
     * Requirements:
     *
     * 1. this Trade need allocation value
     * 2 .Settlement of the last required allocation
     * 3. Maintain records of pending settlements
     * 4. update total last Unclaim amount
     */
    function afterTokenTransfer(
        address op,
        address from,
        address to,
        uint256[] memory ids
    ) external;

    function afterTokenTransfer(
        address op,
        address from,
        address to,
        uint256 id
    ) external;

    /**
     * @notice settle the previous num times of records
     *
     */
    function settleLastUnclaim(uint32 num) external;
}