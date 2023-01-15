// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IRegisterHandler {
    event PublicKey(address indexed owner, bytes key);

    struct Account {
        address owner;
        bytes publicKey;
    }

    function register(Account memory account) external;
}