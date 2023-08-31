// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Errors Library.
 *
 * @notice Introduces some very common input and state validation for smart contracts,
 *      such as non-zero input validation, general boolean expression validation, access validation.
 *
 * @notice Throws pre-defined errors instead of string error messages to reduce gas costs.
 *
 * @notice Since the library handles only very common errors, concrete smart contracts may
 *      also introduce their own error types and handling.
 *
 * @author Basil Gorin
 */
library ErrorHandler {
    /**
     * @notice Thrown on zero input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error ZeroInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error InvalidInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid state in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param errorCode unique error code determining the exact place in code where error was thrown
     */
    error InvalidState(bytes4 fnSelector, uint256 errorCode);

    /**
     * @notice Thrown on invalid access to a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param addr an address which access was denied, usually transaction sender
     */
    error AccessDenied(bytes4 fnSelector, address addr);

    /**
     * @notice Verifies an input is set (non-zero).
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param value a value to check if it's set (non-zero)
     * @param paramIndex function parameter index which is verified
     */
    function verifyNonZeroInput(
        bytes4 fnSelector,
        uint256 value,
        uint8 paramIndex
    ) internal pure {
        if (value == 0) {
            revert ZeroInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies an input is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the input
     * @param paramIndex function parameter index which is verified
     */
    function verifyInput(
        bytes4 fnSelector,
        bool expr,
        uint8 paramIndex
    ) internal pure {
        if (!expr) {
            revert InvalidInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies smart contract state is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the contract state
     * @param errorCode unique error code determining the exact place in code which is verified
     */
    function verifyState(
        bytes4 fnSelector,
        bool expr,
        uint256 errorCode
    ) internal pure {
        if (!expr) {
            revert InvalidState(fnSelector, errorCode);
        }
    }

    /**
     * @notice Verifies an access to the function.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the access
     */
    function verifyAccess(bytes4 fnSelector, bool expr) internal view {
        if (!expr) {
            revert AccessDenied(fnSelector, msg.sender);
        }
    }
}