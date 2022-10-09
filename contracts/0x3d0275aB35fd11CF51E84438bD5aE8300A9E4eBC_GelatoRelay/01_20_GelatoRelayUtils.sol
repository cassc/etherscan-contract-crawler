// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

function _encodeGelatoRelayContext(
    bytes calldata _fnArgs,
    address _feeCollector,
    address _feeToken,
    uint256 _fee
) pure returns (bytes memory) {
    return
        abi.encodePacked(_fnArgs, abi.encode(_feeCollector, _feeToken, _fee));
}