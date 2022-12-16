// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract SyntheticTokenUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](7);
        _callsList[0] = abi.encodeWithSignature("name()");
        _callsList[1] = abi.encodeWithSignature("symbol()");
        _callsList[2] = abi.encodeWithSignature("decimals()");
        _callsList[3] = abi.encodeWithSignature("totalSupply()");
        _callsList[4] = abi.encodeWithSignature("maxTotalSupply()");
        _callsList[5] = abi.encodeWithSignature("isActive()");
        _callsList[6] = abi.encodeWithSignature("poolRegistry()");
    }
}