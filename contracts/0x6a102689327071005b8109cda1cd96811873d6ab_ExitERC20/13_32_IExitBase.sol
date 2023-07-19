// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IExitBase {
    event ExitModuleSetup(address indexed initiator, address indexed avatar);
    event ExitSuccessful(address indexed leaver);

    function exit(uint256 amountToRedeem, address[] calldata tokens) external;
}