// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    /**
     * @notice This function returns the address of the sender of the message.
     * @dev This function is an internal view function that returns the address of the sender of the message.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @notice _msgData() is an internal view function that returns the calldata of the message.
     * @dev This function is used to access the calldata of the message.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}