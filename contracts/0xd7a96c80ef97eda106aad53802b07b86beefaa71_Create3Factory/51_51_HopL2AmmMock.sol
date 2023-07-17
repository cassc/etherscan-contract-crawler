// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HopL2AmmMock {
    address public immutable hToken;
    address public immutable l2CanonicalToken;

    constructor(address _token, address _hToken) {
        l2CanonicalToken = _token;
        hToken = _hToken;
    }

    function exchangeAddress() external view returns (address) {
        return address(this);
    }
}