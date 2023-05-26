pragma solidity 0.7.6;

interface IRewardsManager {
    function transferRewardsToUser(address _account, uint256 _rewards) external;
}