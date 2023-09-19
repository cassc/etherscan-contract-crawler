// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Test DoughAccount.
 * @dev DeFi Smart Account Wallet.
 */

contract Record {
    uint256 public constant version = 3;
}

contract DoughAccountV3 is Record {
    receive() external payable {}
}