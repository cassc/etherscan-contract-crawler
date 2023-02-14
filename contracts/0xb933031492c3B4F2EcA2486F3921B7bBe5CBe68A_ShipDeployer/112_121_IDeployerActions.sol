// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct SetupReturnVars {
    address safeAddress;
    address shipModuleAddress;
}

struct SetupVars {
    string name;
    string symbol;
    uint256 endDuration;
    uint256 minRaise;
    address captain;
    uint256 captainFeeRate;
    address[] nftsAllowed;
}

interface IDeployerActions {
    function createAndSetup(
        SetupVars calldata vars
    ) external returns (SetupReturnVars memory rv);
}