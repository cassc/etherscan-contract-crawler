// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev USED ONLY FOR BACKWARDS COMPTABILITY: 
/// PLEASE USE _encodeRelayContext in GelatoRelayUtils from "relay-context-contracts" pkg.
function _deprecatedRelayContext(
    bytes calldata _data,
    address _feeCollector,
    address _feeToken,
    uint256 _fee
) pure returns (bytes memory) {
    return abi.encodePacked(_data, abi.encode(_feeCollector, _feeToken, _fee));
}