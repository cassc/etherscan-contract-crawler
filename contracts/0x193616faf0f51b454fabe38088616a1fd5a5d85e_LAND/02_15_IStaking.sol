// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

interface IStaking {
    function tickets(address userAddress) external view returns(uint256);

    function totalTickets() external view returns(uint256);

    function stakingEnabled() external view returns (bool);

    function unstakingEnabled() external view returns (bool);
}