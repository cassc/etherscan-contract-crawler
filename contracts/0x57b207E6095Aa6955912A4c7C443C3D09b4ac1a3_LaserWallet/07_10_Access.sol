// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

contract Access {
    error Access__notAllowed();

    modifier access() {
        if (msg.sender != address(this)) revert Access__notAllowed();

        _;
    }
}