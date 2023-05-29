// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IAPWineController {
    function getNextPeriodStart(uint256) external view returns (uint256);

    function withdraw(address, uint256) external;

    function createFYTDelegationTo(
        address,
        address,
        uint256
    ) external;
}