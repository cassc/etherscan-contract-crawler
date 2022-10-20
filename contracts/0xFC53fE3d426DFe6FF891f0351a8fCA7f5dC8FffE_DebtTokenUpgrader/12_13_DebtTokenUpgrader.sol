// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract DebtTokenUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](10);
        calls[0] = abi.encodeWithSignature("totalSupply()");
        calls[1] = abi.encodeWithSignature("lastTimestampAccrued()");
        calls[2] = abi.encodeWithSignature("maxTotalSupply()");
        calls[3] = abi.encodeWithSignature("interestRate()");
        calls[4] = abi.encodeWithSignature("debtIndex()");
        calls[5] = abi.encodeWithSignature("decimals()");
        calls[6] = abi.encodeWithSignature("name()");
        calls[7] = abi.encodeWithSignature("symbol()");
        calls[8] = abi.encodeWithSignature("syntheticToken()");
        calls[9] = abi.encodeWithSignature("isActive()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        _checkUint256Results(_beforeResults, _afterResults, 0, 4);
        _checkUint8Results(_beforeResults, _afterResults, 5, 5);
        _checkStringResults(_beforeResults, _afterResults, 6, 7);
        _checkAddressResults(_beforeResults, _afterResults, 8, 8);
        _checkBooleanResults(_beforeResults, _afterResults, 9, 9);
    }
}