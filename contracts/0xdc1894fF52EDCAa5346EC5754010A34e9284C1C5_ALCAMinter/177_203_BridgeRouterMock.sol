// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

contract BridgeRouterMock {
    uint256 internal immutable _fee;
    uint256 internal _dummy = 0;

    constructor(uint256 fee_) {
        _fee = fee_;
    }

    function routeDeposit(address account, bytes calldata data) external returns (uint256) {
        account = account;
        data = data;
        _dummy = 0;
        return _fee;
    }
}

contract CentralBridgeRouterMock {
    uint256 internal immutable _fee;
    uint256 internal _dummy = 0;

    constructor(uint256 fee_) {
        _fee = fee_;
    }

    function routeDeposit(
        address account,
        uint8 version,
        bytes calldata data
    ) external returns (uint256) {
        account = account;
        data = data;
        version = version;
        _dummy = 0;
        return _fee;
    }
}