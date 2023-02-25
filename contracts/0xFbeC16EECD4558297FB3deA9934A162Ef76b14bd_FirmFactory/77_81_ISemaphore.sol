// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISemaphore {
    error SemaphoreDisallowed();
    
    function canPerform(address caller, address target, uint256 value, bytes calldata data, bool isDelegateCall) external view returns (bool);
    function canPerformMany(address caller, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bool isDelegateCall) external view returns (bool);
}