// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum ChargeType {
    NONE, // No charge
    ETH,  // Charge amount is in Eth (Wei)
    ERC20 // Charge amount is in an ERC20 token (token field) in minor denomination
}

/**
 * @dev The Charge struct represents details of a charge made to the gatekeeper on
 * gateway token issuance or refresh.
 */
struct Charge {
    uint256 value;
    ChargeType chargeType;
    address token;
    address recipient;
}