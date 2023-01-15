// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "../RegisterHandler.sol";

contract L1Register is RegisterHandler {
    // Get credential public key from a user's address
    mapping(address => bytes) public userPubkey;
    // Is a public key registered
    mapping(bytes => bool) public isPubkeyRegistered;

    function _register(Account memory _account) internal override {
        userPubkey[_account.owner] = _account.publicKey;
        isPubkeyRegistered[_account.publicKey] = true;
        emit PublicKey(_account.owner, _account.publicKey);
    }
}