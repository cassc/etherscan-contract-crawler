// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBrightIDValidator {
    /**
     * @dev Returns the context of the BrightID valiator.
     */
    function context() external view returns (bytes32);

    /**
     * @dev Returns true if `signer` is a trusted validator, and false otherwise.
     */
    function isTrustedValidator(address signer) external view returns (bool);
}