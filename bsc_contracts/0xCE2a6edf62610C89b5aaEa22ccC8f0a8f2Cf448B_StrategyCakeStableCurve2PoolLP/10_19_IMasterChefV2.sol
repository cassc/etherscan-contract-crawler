// SPDX-License-Identifier: Elastic-2.0
pragma solidity 0.8.9;

interface IMasterChefV2 {

    /// Address of MCV1 contract.
    function MASTER_CHEF() external returns (address);

    /// Address of CAKE contract.
    function CAKE() external view returns (address);
    
    /// The whitelist of addresses allowed to deposit in special pools.
    function whiteList(address) external  returns (bool);

    /// The pool id of the MCV2 mock token pool in MCV1.
    function MASTER_PID() external  returns (uint256);

    /// Total regular allocation points. Must be the sum of all regular pools' allocation points.
    function totalRegularAllocPoint() external view returns (uint256);

    /// Total special allocation points. Must be the sum of all special pools' allocation points.
    function totalSpecialAllocPoint() external returns (uint256);

    /// 40 cakes per block in MCV1
    function MASTERCHEF_CAKE_PER_BLOCK() external returns (uint256);

    /// uint256 public constant ACC_CAKE_PRECISION = 1e18;
    function ACC_CAKE_PRECISION() external returns (uint256);

    /// Basic boost factor, none boosted user's boost factor
    function BOOST_PRECISION() external returns (uint256);

    /// Hard limit for maxmium boost factor, it must greater than BOOST_PRECISION
    function MAX_BOOST_PRECISION() external returns (uint256);

    /// total cake rate = toBurn + toRegular + toSpecial
    function CAKE_RATE_TOTAL_PRECISION() external returns (uint256);

    /// CAKE distribute % for burn
    function cakeRateToBurn() external returns (uint256);

    /// CAKE distribute % for regular farm pool
    function cakeRateToRegularFarm() external returns (uint256);

    /// CAKE distribute % for special pools
    function cakeRateToSpecialFarm() external returns (uint256);

    /// uint256 public lastBurnedBlock;
    function lastBurnedBlock() external returns (uint256);

    /// Address of the LP token for each MCV2 pool.
    function lpToken(uint256 _pid) external view returns (address);
    
    /// Info of each pool user.
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    /// PoolInfo[] public poolInfo;
    function poolInfo(uint256 _pid) external view returns (uint256, uint256, uint256, uint256, bool);

    /// Returns the number of MCV2 pools.
    function poolLength() external view returns (uint256 pools);

    /// View function for checking pending CAKE rewards.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _user Address of the user.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
 
    /// Update cake reward for all the active pools. Be careful of gas spending!
    function massUpdatePools() external;

    /// Calculates and returns the `amount` of CAKE per block.
    /// @param _isRegular If the pool belongs to regular or special.
    function cakePerBlock(bool _isRegular) external view returns (uint256 amount);

    /// Calculates and returns the `amount` of CAKE per block to burn.
    function cakePerBlockToBurn() external view returns (uint256 amount);

    /// @notice Deposit LP tokens to pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to deposit.
    function deposit(uint256 _pid, uint256 _amount) external;

    /// @notice Withdraw LP tokens from pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to withdraw.
    function withdraw(uint256 _pid, uint256 _amount) external;

    /// @notice Harvests CAKE from `MASTER_CHEF` MCV1 and pool `MASTER_PID` to MCV2.
    function harvestFromMasterChef() external;

    /// @notice Withdraw without caring about the rewards. EMERGENCY ONLY.
    /// @param _pid The id of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) external;

    /// @notice Get user boost multiplier for specific pool id.
    /// @param _user The user address.
    /// @param _pid The pool id.
    function getBoostMultiplier(address _user, uint256 _pid) external view returns (uint256);
}