// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapERC20Errors {
    /**
     * @notice Permit deadline was exceeded
     */
    error PermitExpired();

    /**
     * @notice Permit signature invalid
     */
    error PermitInvalidSignature();
}