// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

struct GasFee {
    uint256 amount;
    address token;
    address collector;
}

/**
 * @dev Interface that must be implemented by an automation gas vendor.
 */
interface IGasVendor {
    /**
     * @dev Checks for gas fee to pay and returns its details: amount, token,
     * and collector address to send the amount of the token to.
     *
     * When no fee payment required, the function returns all of these fields set
     * to '0'. The caller must check this before sending payment since an attempt
     * to perform a transfer with such parameters will fail contract execution.
     */
    function getGasFee(address msgSender, bytes calldata msgData) external returns (GasFee memory);
}