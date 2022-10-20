// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolRegistryUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](2);
        calls[0] = abi.encodeWithSignature("masterOracle()");
        calls[1] = abi.encodeWithSignature("feeCollector()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        _checkAddressResults(_beforeResults, _afterResults, 0, 1);
    }
}