//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/**
 * @dev Message Validation Interface
 */
interface IMessageValidator {
    /**
     * @dev Validation Result.
     * Contains the result and error message. If the given string value is valid, `message` should be empty.
     */
    struct Result {
        bool isValid;
        string message;
    }

    /**
     * @dev Validates given string value and returns validation result.
     */
    function validate(string memory _msg) external view returns (Result memory);
}