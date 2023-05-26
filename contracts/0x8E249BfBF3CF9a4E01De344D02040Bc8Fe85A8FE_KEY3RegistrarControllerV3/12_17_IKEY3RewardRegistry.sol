// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3RewardRegistry {
    struct Reward {
        string name;
        uint256 claimedAt;
        uint256 expiredAt;
        bool claimed;
    }

    event Claim(address indexed user, string name);

    function baseNode() external view returns (bytes32);

    function rewardsOf(address user) external view returns (Reward[] memory);

    function exists(address user, string memory name)
        external
        view
        returns (bool, uint);

    function claim(address user) external returns (string[] memory);
}