// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBentLocker {
    function balanceOf(address user) external view returns (uint256);
    function claimAll() external;
    function claim(uint256[] calldata pids) external;
    function decimals() external pure returns (uint256);
    function deposit(uint256 amount) external;
    function epochExpireAt(uint256 epoch) external view returns (uint256);
    function initialize(address _bent, address _bentCVX, address[] memory _rewardTokens, uint256 windowLength, uint256 _epochLength, uint256 _lockDurationInEpoch) external;
    function lockedBalances(address user) external view returns (uint256 unlockable, uint256 locked, uint256 total);
    function name() external pure returns (string memory);
    function owner() external view returns (address);
    function removeRewardToken(uint256 index) external;
    function renounceOwnership() external;
    function streamInfo() external view returns (uint256 windowLength, uint256 endRewardBlock);
    function totalSupply() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function unlockableBalances(address user) external view returns (uint256);
    function withdraw(uint256 shares) external;
}