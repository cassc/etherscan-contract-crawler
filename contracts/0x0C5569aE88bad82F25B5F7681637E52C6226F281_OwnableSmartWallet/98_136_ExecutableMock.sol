// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract ExecutableMock {
    bytes internal _lastCallData;
    uint256 internal _lastValue;

    fallback() external payable {
        _lastCallData = msg.data;
        _lastValue = msg.value;
    }

    receive() external payable {
        require(
            msg.value > 0,
            "Contract was called with value but no ETH was passed"
        );
    }

    function getCallData() public view returns (bytes memory) {
        return _lastCallData;
    }

    function getValue() public view returns (uint256) {
        return _lastValue;
    }
}