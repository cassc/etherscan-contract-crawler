interface IMasterChef {
    function pendingSpyn(uint256 _pid, address _user)
    external
    view
    returns (uint256);

    function canHarvest(uint256 _pid, address _user)
    external
    view
    returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function poolInfo(uint256 _pid) external view returns (
        address lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accSpynPerShare,
        uint256 harvestInterval,
        uint256 extraHarvestInterval,
        uint256 lpLockUntil,
        uint256 extraLockInterval
    );

    function userInfo(uint256 _pid, address _user) external view returns (
        uint256 amount,
        uint256 rewardDebt,
        uint256 rewardLockedUp,
        uint256 nextHarvestUntil
    );

    function totalAllocPoint() external view returns (uint256);



}