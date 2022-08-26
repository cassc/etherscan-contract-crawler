pragma solidity 0.8.6;

interface IJellyRewarder {

    // function setRewards( 
    //     uint256[] memory rewardPeriods, 
    //     uint256[] memory amounts
    // ) external;
    // function setBonus(
    //     uint256 poolId,
    //     uint256[] memory rewardPeriods,
    //     uint256[] memory amounts
    // ) external;
    function updateRewards() external returns(bool);
    // function updateRewards(address _pool) external returns(bool);

    function totalRewards(address _poolAddress) external view returns (uint256 rewards);
    function totalRewards() external view returns (address[] memory, uint256[] memory);
    // function poolRewards(uint256 _pool, uint256 _from, uint256 _to) external view returns (uint256 rewards);
    function poolRewards(address _pool, address _rewardToken, uint256 _from, uint256 _to) external view returns (uint256 rewards);

    function rewardTokens() external view returns (address[] memory rewards);
    function rewardTokens(address _pool) external view returns (address[] memory rewards);

    function poolCount() external view returns (uint256);

    function setPoolPoints(address _poolAddress, uint256 _poolPoints) external;

    function setVault(address _addr) external;
    function addRewardsToPool(
        address _poolAddress,
        address _rewardAddress,
        uint256 _startTime,
        uint256 _duration,
        uint256 _amount

    ) external ;

}