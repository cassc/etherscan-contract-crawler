// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

enum VotingPower {
    A,
    B,
    ZERO_VOTING_POWER
}

struct VestingContract {
    address contractAddress; // vesting contract address
    VotingPower votingPower; // enum for voting power(0 means "A", 1 means "B" and 2 means "ZERO VOTING")
}

interface ITokenDistributorOld {
    function masterVestingContract() external view returns (address);

    function vestingContracts(address contributor) external view returns (VestingContract memory);

    function weightA() external view returns (uint256);

    function weightB() external view returns (uint256);

    function contributorsList() external view returns (address[] memory);

    function countContributors() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);
}