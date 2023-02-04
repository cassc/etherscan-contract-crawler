// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Wrappable {

    uint16 private _originChain;
    string private _originToken;

    constructor(uint16 originChain_, string memory originToken_) {
        _originChain = originChain_;
        _originToken = originToken_;
    }

    function originChain() public view returns (uint16) {
        return _originChain;
    }

    function originToken() public view returns (string memory) {
        return _originToken;
    }

}