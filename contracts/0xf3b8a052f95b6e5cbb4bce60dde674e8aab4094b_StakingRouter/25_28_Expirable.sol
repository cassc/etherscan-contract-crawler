// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Expirable {

    modifier expires(uint256 expiresAt) {
        require(expiresAt >= block.timestamp, 'EXPIRED');
        _;
    }
}