// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract ESMET721Upgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function _calls() internal pure override returns (bytes[] memory calls) {
        calls = new bytes[](5);
        calls[0] = abi.encodeWithSignature("name()");
        calls[1] = abi.encodeWithSignature("symbol()");
        calls[2] = abi.encodeWithSignature("baseTokenURI()");
        calls[3] = abi.encodeWithSignature("esMET()");
        calls[4] = abi.encodeWithSignature("nextTokenId()");
    }

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {
        _checkStringResults(_beforeResults, _afterResults, 0, 2);
        _checkAddressResults(_beforeResults, _afterResults, 3, 3);
        _checkUint256Results(_beforeResults, _afterResults, 4, 4);
    }
}