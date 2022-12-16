// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](12);
        _callsList[0] = abi.encodeWithSignature("debtFloorInUsd()");
        _callsList[1] = abi.encodeWithSignature("depositFee()");
        _callsList[2] = abi.encodeWithSignature("issueFee()");
        _callsList[3] = abi.encodeWithSignature("withdrawFee()");
        _callsList[4] = abi.encodeWithSignature("repayFee()");
        _callsList[5] = abi.encodeWithSignature("liquidationFees()");
        _callsList[6] = abi.encodeWithSignature("swapFee()");
        _callsList[7] = abi.encodeWithSignature("maxLiquidable()");
        _callsList[8] = abi.encodeWithSignature("treasury()");
        _callsList[9] = abi.encodeWithSignature("poolRegistry()");
        _callsList[10] = abi.encodeWithSignature("isSwapActive()");
        _callsList[11] = abi.encodeWithSignature("governor()");
    }
}