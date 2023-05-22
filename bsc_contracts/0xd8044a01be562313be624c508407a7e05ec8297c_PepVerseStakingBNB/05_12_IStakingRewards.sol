pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function withdrawableAmount(address account)external view returns(uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
    
    function notifyRewardAmount(uint256 amount) external;
    
    function setRewardsDuration(uint256 _rewardsDuration) external;
    
    function setLockDownDuration(uint256 _lockdownDuration) external ;
    
    function rewardsDistribution() external view returns(address);
    
    function rewardsDuration() external view returns(uint256);
    
    function lockDownDuration() external view returns(uint256);

    function setWithdrawRate(uint256 _rate) external ;

    function withdrawRate() external view returns(uint256);

    function setFeeCollector(address _feeCollector) external; 

    function feeCollector() external view returns(address);
}