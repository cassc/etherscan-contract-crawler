// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title Access
 *
 * @author Inspired by Gnosis Safe.
 *
 * @notice Modifier that only allows this contract to be the 'msg.sender'.
 */
contract Access {
    error Access__notAllowed();

    modifier access() {
        if (msg.sender != address(this)) revert Access__notAllowed();

        _;
    }
}