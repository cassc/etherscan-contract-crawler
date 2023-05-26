// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// https://github.com/rarible/protocol-contracts/blob/master/royalties/contracts/LibPart.sol

library LibPart {
    struct Part {
        address payable account;
        uint96 value;
    }
}