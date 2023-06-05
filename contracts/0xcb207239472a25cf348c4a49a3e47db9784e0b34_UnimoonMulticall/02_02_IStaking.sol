// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStaking {
    struct Data {
        uint256 value;
        uint64 lockedFrom;
        uint64 lockedUntil;
        uint256 weight;
        uint256 lastAccValue;
        uint256 pendingYield;
    }

    function increaseRewardPool(uint256 amount) external;

    function getAllocAndWeight() external view returns (uint256, uint256);

    function pendingRewardPerDeposit(
        address user,
        uint8 pid,
        uint256 stakeId
    ) external view returns (uint256);

    function getUserStakes(address user, uint256 pid)
        external
        view
        returns (Data[] memory);
}