pragma solidity ^0.8.13;

interface IAuraLocker {
    function delegate(address _newDelegate) external;

    function lock(address _account, uint256 _amount) external;

    function lockedBalances(address _account) view external returns (uint);

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function balanceOf(address _user) external view returns (uint256);

    function rewardTokens() external view returns (address[] memory);
}
