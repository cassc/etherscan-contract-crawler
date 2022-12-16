// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract DepositTokenUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](9);
        _callsList[0] = abi.encodeWithSignature("name()");
        _callsList[1] = abi.encodeWithSignature("symbol()");
        _callsList[2] = abi.encodeWithSignature("decimals()");
        _callsList[3] = abi.encodeWithSignature("totalSupply()");
        _callsList[4] = abi.encodeWithSignature("maxTotalSupply()");
        _callsList[5] = abi.encodeWithSignature("collateralFactor()");
        _callsList[6] = abi.encodeWithSignature("underlying()");
        _callsList[7] = abi.encodeWithSignature("isActive()");
        _callsList[8] = abi.encodeWithSignature("governor()");
    }
}