// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberOrderCanceler {
    /**
     * @notice Struct for passing parameters to the function that cancels orders.
     * @param market The address of the market on which the orders are to be canceled.
     * @param tokenIds An array of ids of orders to cancel.
     */
    struct CancelParams {
        address market;
        uint256[] tokenIds;
    }

    /**
     * @notice Cancel orders across markets.
     * @param paramsList The list of CancelParams.
     */
    function cancel(CancelParams[] calldata paramsList) external;

    /**
     * @notice Cancel orders across markets.
     * @param paramsList The list of CancelParams.
     * @param to The address to receive the canceled assets.
     */
    function cancelTo(CancelParams[] calldata paramsList, address to) external;
}