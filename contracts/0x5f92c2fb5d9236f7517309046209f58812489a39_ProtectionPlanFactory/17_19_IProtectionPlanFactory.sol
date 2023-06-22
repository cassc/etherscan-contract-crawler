// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IProtectionPlanFactory {
    error ProtectionPlanExistsForUser();
    error NonceAlreadyUsed();
    error DeadlineExceeded();
    error InvalidSignature();
    function createNewProtectionPlan(uint256 _nonce, uint256 _deadline, bytes memory _signature) external;
}