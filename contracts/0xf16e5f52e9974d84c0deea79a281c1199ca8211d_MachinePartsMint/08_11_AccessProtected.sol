// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

abstract contract AccessProtected {
    modifier onlyUser() {
        require(
            tx.origin == msg.sender,
            "Access Protected: The caller is another contract"
        );
        _;
    }
}