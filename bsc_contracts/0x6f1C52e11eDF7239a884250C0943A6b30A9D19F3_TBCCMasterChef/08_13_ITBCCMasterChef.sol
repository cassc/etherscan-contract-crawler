// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITBCCMasterChef {

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 accTFTPerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
    }

    struct BonusInfo {
        uint256 startBlock;
        uint256 bonus;
    }

    /**
     * @notice Returns the number of TBCCMCV pools.
     *
     */
    function poolLength() external view returns (uint256);

    /**
     * @notice Migrate LP token to another LP contract through the `migrator` contract.
     * @param _pid: The index of the pool. See `poolInfo`.
     *
     */
    function migrate(
        uint256 _pid
    ) external;

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: Start block
     * @param _to: End Block
     *
     */
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) external view returns (uint256);

    /**
     * @notice View function for checking pending TBCC rewards.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _user: Address of the user.
     *
     */
    function pendingReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256);

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     *
     */
    function massUpdatePools() external;

    /**
     * @notice Update reward variables for the given pool.
     * @param _pid: The id of the pool. See `poolInfo`.
     *
     */
    function updatePool(
        uint256 _pid
    ) external returns (PoolInfo memory);

    /**
     * @notice Deposit LP tokens to pool.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _amount: Amount of LP tokens to deposit.
     * @param _to: The receiver of `amount` deposit benefit.
     *
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    /**
     * @notice Withdraw LP tokens from pool.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _amount: Amount of LP tokens to withdraw.
     * @param _to: Receiver of the LP tokens.
     *
     */
    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    /**
     * @notice Harvest proceeds for transaction sender to `to`.
     * @param _pid: The index of the pool. See `poolInfo`.
     * @param _to: Receiver of the TBCC rewards.
     *
     */
    function harvest(
        uint256 _pid,
        address _to
    ) external;

    /**
     * @notice Withdraw without caring about the rewards. EMERGENCY ONLY.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _to: Receiver of the LP tokens.
     *
     */
    function emergencyWithdraw(
        uint256 _pid,
        address _to
    ) external;
}