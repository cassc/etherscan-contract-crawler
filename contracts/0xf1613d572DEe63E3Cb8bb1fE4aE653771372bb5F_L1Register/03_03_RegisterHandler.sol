// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { IRegisterHandler } from "./interfaces/IRegisterHandler.sol";

contract RegisterHandler is IRegisterHandler {
    function register(Account memory _account) public override {
        require(_account.owner == msg.sender, "only owner can be registered");
        _register(_account);
    }

    function _register(Account memory _account) internal virtual {
        emit PublicKey(_account.owner, _account.publicKey);
    }
}