// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](11);
        calls[0] = abi.encodeWithSignature("debtFloorInUsd()");
        calls[1] = abi.encodeWithSignature("depositFee()");
        calls[2] = abi.encodeWithSignature("issueFee()");
        calls[3] = abi.encodeWithSignature("withdrawFee()");
        calls[4] = abi.encodeWithSignature("repayFee()");
        calls[5] = abi.encodeWithSignature("liquidationFees()");
        calls[6] = abi.encodeWithSignature("swapFee()");
        calls[7] = abi.encodeWithSignature("maxLiquidable()");
        calls[8] = abi.encodeWithSignature("treasury()");
        calls[9] = abi.encodeWithSignature("poolRegistry()");
        calls[10] = abi.encodeWithSignature("isSwapActive()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        _checkUint256Results(_beforeResults, _afterResults, 0, 7);
        _checkAddressResults(_beforeResults, _afterResults, 8, 9);
        _checkBooleanResults(_beforeResults, _afterResults, 10, 10);
    }
}