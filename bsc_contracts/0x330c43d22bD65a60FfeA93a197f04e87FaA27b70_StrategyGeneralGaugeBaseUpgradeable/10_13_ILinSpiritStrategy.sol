// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ILinSpiritStrategy {
    function balanceOfInSpirit() external view returns (uint256);

    function deposit(address, address) external;

    function withdraw(address) external;

    function withdraw(
        address,
        address,
        uint256
    ) external;

    function withdrawAll(address, address) external;

    function createLock(uint256, uint256) external;

    function increaseAmount(uint256) external;

    function increaseTime(uint256) external;

    function release() external;

    function claimGaugeReward(address _gauge) external;

    function claimSpirit(address) external returns (uint256);

    function claimRewards(address) external;

    function claimFees(address, address) external;

    function claimVotingFees(
        address gauge, 
        address token0, 
        address token1, 
        address to
    ) external;

    function setStashAccess(address, bool) external;

    function vote(
        address[] calldata _tokenVote,
        uint256[] calldata _weights
    ) external;

    function voteV2(
        address proxy,
        address[] calldata _tokenVote,
        uint256[] calldata _weights
    ) external;

    function voteGaugeWeight(address, uint256) external;

    function balanceOfPool(address) external view returns (uint256);

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);

    function getVotingRewards() external;
}