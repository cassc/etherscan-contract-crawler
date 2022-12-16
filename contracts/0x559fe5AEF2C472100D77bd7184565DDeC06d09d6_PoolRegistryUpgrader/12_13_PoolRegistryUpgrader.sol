// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract PoolRegistryUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](3);
        _callsList[0] = abi.encodeWithSignature("masterOracle()");
        _callsList[1] = abi.encodeWithSignature("feeCollector()");
        _callsList[2] = abi.encodeWithSignature("governor()");
    }
}