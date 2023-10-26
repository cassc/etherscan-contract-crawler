// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Test DoughAccount.
 * @dev DeFi Smart Account Wallet.
 */

contract Record {
    uint256 public constant version = 4;
}

contract DoughAccountV4 is Record {
    receive() external payable {}
}