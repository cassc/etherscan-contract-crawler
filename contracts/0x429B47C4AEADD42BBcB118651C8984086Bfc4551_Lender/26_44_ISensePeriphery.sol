// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ISensePeriphery {
    function divider() external view returns (address);

    function swapUnderlyingForPTs(
        address,
        uint256,
        uint256,
        uint256
    ) external returns (uint256);

    function verified(address) external view returns (bool);
}