// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
// With _msgData() removed

pragma solidity ^0.8.10;

/**
 * @dev Provides the msg.sender in the current execution context.
 */
abstract contract ContextSimple {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}