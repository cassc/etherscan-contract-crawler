// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract ESMETUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](8);
        calls[0] = abi.encodeWithSignature("decimals()");
        calls[1] = abi.encodeWithSignature("name()");
        calls[2] = abi.encodeWithSignature("symbol()");
        calls[3] = abi.encodeWithSignature("esMET721()");
        calls[4] = abi.encodeWithSignature("rewards()");
        calls[5] = abi.encodeWithSignature("totalLocked()");
        calls[6] = abi.encodeWithSignature("totalBoosted()");
        calls[7] = abi.encodeWithSignature("exitPenalty()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        _checkUint8Results(_beforeResults, _afterResults, 0, 0);
        _checkStringResults(_beforeResults, _afterResults, 1, 2);
        _checkAddressResults(_beforeResults, _afterResults, 3, 4);
        _checkUint256Results(_beforeResults, _afterResults, 5, 7);
    }
}