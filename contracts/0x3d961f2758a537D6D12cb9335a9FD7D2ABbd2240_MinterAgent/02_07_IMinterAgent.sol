// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMinterAgent {
    error ALREADY_INITIALIZED();
    error ONLY_OWNER();
    error ARRAY_LENGTH_MISMATCH();

    function initialize(address _owner, address _receiver) external;

    function forwardCall(address _target, bytes calldata _cd, uint256 _value) external payable returns (bool success, bytes memory data);

    function forwardCallBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values
    ) external payable returns (bool success, bytes memory data);
}