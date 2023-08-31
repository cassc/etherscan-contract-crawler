// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Errors library
 * @author Peppersec
 * @notice Defines the error messages emitted by the different contracts of the Donate contract
 */
library Errors {
    // The caller of the function is not a account owner
    string public constant INVALID_SIGNER = '1';
    // The caller of the function is not a account contract
    string public constant RECEIVE_FALLBACK_PROHIBITED = '2';
}