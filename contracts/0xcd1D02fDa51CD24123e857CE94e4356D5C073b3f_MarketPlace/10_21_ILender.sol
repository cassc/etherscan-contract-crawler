// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ILender {
    function approve(
        address,
        address,
        address,
        address,
        address
    ) external;

    function transferFYTs(address, uint256) external;

    function transferPremium(address, uint256) external;

    function paused(uint8) external returns (bool);

    function halted() external returns (bool);
}