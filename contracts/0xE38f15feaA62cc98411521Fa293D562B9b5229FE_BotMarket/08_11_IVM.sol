// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IVotemarket {
    /// @notice Bribe struct requirements.
    struct Bribe {
        // Address of the target gauge.
        address gauge;
        // Manager.
        address manager;
        // Address of the ERC20 used for rewards.
        address rewardToken;
        // Number of periods.
        uint8 numberOfPeriods;
        // Timestamp where the bribe become unclaimable.
        uint256 endTimestamp;
        // Max Price per vote.
        uint256 maxRewardPerVote;
        // Total Reward Added.
        uint256 totalRewardAmount;
        // Blacklisted addresses.
        address[] blacklist;
    }

    function nextID() external view returns (uint256);
    function claimAllFor(address _user, uint256[] calldata ids) external;
    function getBribe(uint256 bribeId) external view returns (Bribe memory);
    function claimable(address user, uint256 bribeId) external view returns (uint256 amount);
    function setRecipientFor(address _user, address _recipient) external;
    function owner() external view returns (address);
}