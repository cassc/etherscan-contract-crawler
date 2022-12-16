// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract DebtTokenUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](11);
        _callsList[0] = abi.encodeWithSignature("totalSupply()");
        _callsList[1] = abi.encodeWithSignature("lastTimestampAccrued()");
        _callsList[2] = abi.encodeWithSignature("maxTotalSupply()");
        _callsList[3] = abi.encodeWithSignature("interestRate()");
        _callsList[4] = abi.encodeWithSignature("debtIndex()");
        _callsList[5] = abi.encodeWithSignature("decimals()");
        _callsList[6] = abi.encodeWithSignature("name()");
        _callsList[7] = abi.encodeWithSignature("symbol()");
        _callsList[8] = abi.encodeWithSignature("syntheticToken()");
        _callsList[9] = abi.encodeWithSignature("isActive()");
        _callsList[10] = abi.encodeWithSignature("governor()");
    }
}