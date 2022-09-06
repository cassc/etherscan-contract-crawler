//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract LinearPool is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint32 private constant ONE_YEAR = 365;
    uint64 public constant PERCENTAGE_CONST = 10000;

    // The accepted token
    IERC20 public linearAcceptedToken;
    // The reward distribution address
    address public linearRewardDistributor;
    // Info of each pool
    LinearPoolInfo[] public linearPoolInfo;
    // Info of each user that stakes in pools
    mapping(uint256 => mapping(address => LinearStakingData))
        public linearStakingData;
    // The flexible lock duration. Users who stake in the flexible pool will be affected by this
    uint256 public linearFlexLockDuration;

    // The % of soon unstake fee
    address public feeReceiverAddress;

    event LinearPoolCreated(uint256 indexed poolId, uint256 APR);
    event LinearPoolUpdated(
        uint256 indexed poolId,
        uint64 unstakeFee,
        uint256 minInvestment,
        bool extendedPeriod
    );
    event LinearDeposit(
        uint256 poolId,
        address indexed account,
        uint256 amount
    );
    event LinearWithdraw(
        uint256 poolId,
        address indexed account,
        uint256 amount,
        uint256 fee
    );
    event LinearRewardsHarvested(
        uint256 poolId,
        address indexed account,
        uint256 reward
    );

    struct LinearPoolInfo {
        uint256 totalStaked;
        uint256 minInvestment;
        uint64 APR;
        uint256 lockDuration;
        bool extendedPeriod;
        uint64 unstakeFee;
    }

    struct LinearStakingData {
        uint256 balance;
        uint256 joinTime;
        uint256 updatedTime;
        uint256 userMinInvestment;
    }

    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _acceptedToken the token that the pools will use as staking and reward token
     */
    function __LinearPool_init(IERC20 _acceptedToken) internal {
        __Ownable_init();
        feeReceiverAddress = msg.sender;
        linearAcceptedToken = _acceptedToken;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _poolId id of the pool
     */
    modifier linearValidatePoolById(uint256 _poolId) {
        require(
            _poolId < linearPoolInfo.length,
            "LinearStakingPool: Pool are not exist"
        );
        _;
    }

    /**
     * @notice Return total number of pools
     */
    function linearPoolLength() external view returns (uint256) {
        return linearPoolInfo.length;
    }

    /**
     * @notice Return total tokens staked in a pool
     * @param _poolId id of the pool
     */
    function linearTotalStaked(uint256 _poolId)
        external
        view
        linearValidatePoolById(_poolId)
        returns (uint256)
    {
        return linearPoolInfo[_poolId].totalStaked;
    }

    /**
     * @notice Add a new pool with different APR and conditions. Can only be called by the owner.
     * @param _minInvestment the minimum investment amount users need to use in order to join the pool.
     * @param _APR the APR rate of the pool.
     * @param _lockDuration the duration users need to wait before being able to withdraw and claim the rewards.
     */
    function linearAddPool(
        uint256 _minInvestment,
        uint64 _APR,
        uint256 _lockDuration
    ) external onlyOwner {
        linearPoolInfo.push(
            LinearPoolInfo({
                totalStaked: 0,
                minInvestment: _minInvestment,
                APR: _APR,
                lockDuration: _lockDuration,
                extendedPeriod: false,
                unstakeFee: 2500
            })
        );
        emit LinearPoolCreated(linearPoolInfo.length - 1, _APR);
    }

    /**
     * @notice Update the given pool's info. Can only be called by the owner.
     * @param _poolId id of the pool
     * @param _unstakeFee the early unstake fee.
     * @param _minInvestment the minimum investment amount users need to use in order to join the pool.
     * @param _extendedPeriod extension for calculate reward after lock time.
     */
    function linearSetPool(
        uint256 _poolId,
        uint64 _unstakeFee,
        uint256 _minInvestment,
        bool _extendedPeriod
    ) external onlyOwner linearValidatePoolById(_poolId) {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];

        require(_unstakeFee <= 9000, "LinearStakingPool: value exceeded limit");

        pool.extendedPeriod = _extendedPeriod;
        pool.minInvestment = _minInvestment;
        pool.unstakeFee = _unstakeFee;

        emit LinearPoolUpdated(
            _poolId,
            _unstakeFee,
            _minInvestment,
            _extendedPeriod
        );
    }

    /**
     * @notice Set the flexible lock time. This will affects the flexible pool.  Can only be called by the owner.
     * @param _flexLockDuration the minimum lock duration
     */
    function linearSetFlexLockDuration(uint256 _flexLockDuration)
        external
        onlyOwner
    {
        linearFlexLockDuration = _flexLockDuration;
    }

    /**
     * @notice Set the early ustake fee receiver address.  Can only be called by the owner.
     * @param _receiver fee receiver address
     */
    function linearSetFeeReceiverAddress(address _receiver) external onlyOwner {
        require(_receiver != address(0), "LinearStakingPool: invalid receiver");

        feeReceiverAddress = _receiver;
    }

    /**
     * @notice Set the reward distributor. Can only be called by the owner.
     * @param _linearRewardDistributor the reward distributor
     */
    function linearSetRewardDistributor(address _linearRewardDistributor)
        external
        onlyOwner
    {
        require(
            _linearRewardDistributor != address(0),
            "LinearStakingPool: invalid reward distributor"
        );
        linearRewardDistributor = _linearRewardDistributor;
    }

    /**
     * @notice Deposit token to earn rewards
     * @param _poolId id of the pool
     * @param _amount amount of token to deposit
     */
    function _linearDeposit(uint256 _poolId, uint256 _amount) internal {
        address account = msg.sender;

        _linearExecuteDeposit(_poolId, _amount, account);

        emit LinearDeposit(_poolId, account, _amount);
    }

    /**
     * @notice Withdraw token from a pool
     * @param _poolId id of the pool
     * @param _amount amount to withdraw
     */
    function _linearWithdraw(uint256 _poolId, uint256 _amount)
        internal
        returns (uint256, uint256)
    {
        address account = msg.sender;
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        uint256 lockDuration = pool.lockDuration > 0
            ? pool.lockDuration
            : linearFlexLockDuration;

        require(
            stakingData.balance >= _amount,
            "LinearStakingPool: invalid withdraw amount"
        );

        uint256 reward = linearPendingReward(_poolId, account);
        uint256 fee = 0;

        if (block.timestamp < stakingData.joinTime + lockDuration) {
            fee = (_amount * pool.unstakeFee) / PERCENTAGE_CONST;
            reward = 0;
        }

        if (reward > 0) {
            require(
                linearRewardDistributor != address(0),
                "LinearStakingPool: invalid reward distributor"
            );

            linearAcceptedToken.safeTransferFrom(
                linearRewardDistributor,
                account,
                reward
            );
            emit LinearRewardsHarvested(_poolId, account, reward);
        }

        stakingData.balance -= _amount;
        stakingData.updatedTime = block.timestamp;

        stakingData.userMinInvestment = (stakingData.balance * 25) / 100;

        if (fee > 0) {
            linearAcceptedToken.safeTransfer(feeReceiverAddress, fee);
        }
        emit LinearWithdraw(_poolId, account, _amount, fee);

        return (_amount - fee, _amount);
    }

    /**
     * @notice Gets number of reward tokens of a user from a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return reward earned reward of a user
     */
    function linearPendingReward(uint256 _poolId, address _account)
        public
        view
        linearValidatePoolById(_poolId)
        returns (uint256 reward)
    {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        reward = pool.extendedPeriod
            ? _linearExtendedPendingReward(_poolId, _account)
            : _linearLockPendingReward(_poolId, _account);
    }

    /**
     * @notice Gets number of deposited tokens in a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return total token deposited in a pool by a user
     */
    function linearBalanceOf(uint256 _poolId, address _account)
        external
        view
        linearValidatePoolById(_poolId)
        returns (uint256)
    {
        return linearStakingData[_poolId][_account].balance;
    }

    function _linearExecuteDeposit(
        uint256 _poolId,
        uint256 _amount,
        address account
    ) internal {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            account
        ];

        uint256 reward = linearPendingReward(_poolId, account);

        if (reward > 0) {
            require(
                linearRewardDistributor != address(0),
                "LinearStakingPool: invalid reward distributor"
            );

            linearAcceptedToken.safeTransferFrom(
                linearRewardDistributor,
                account,
                reward
            );
            emit LinearRewardsHarvested(_poolId, account, reward);
        }

        stakingData.balance += _amount;
        stakingData.joinTime = block.timestamp;
        stakingData.updatedTime = block.timestamp;

        stakingData.userMinInvestment = (stakingData.balance * 25) / 100;

        pool.totalStaked += _amount;
    }

    function _linearLockPendingReward(uint256 _poolId, address _account)
        private
        view
        linearValidatePoolById(_poolId)
        returns (uint256 reward)
    {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            _account
        ];

        uint256 startTime = stakingData.updatedTime > 0
            ? stakingData.updatedTime
            : block.timestamp;

        uint256 endTime = block.timestamp;
        if (
            pool.lockDuration > 0 &&
            stakingData.joinTime + pool.lockDuration < block.timestamp
        ) {
            endTime = stakingData.joinTime + pool.lockDuration;
        }

        uint256 stakedDays = endTime > startTime
            ? (endTime - startTime) / (1 days)
            : 0;
        uint256 pendingReward = ((stakingData.balance * stakedDays * pool.APR) /
            ONE_YEAR) / 100;

        reward = pendingReward;
    }

    function _linearExtendedPendingReward(uint256 _poolId, address _account)
        private
        view
        linearValidatePoolById(_poolId)
        returns (uint256 reward)
    {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];
        LinearStakingData storage stakingData = linearStakingData[_poolId][
            _account
        ];

        uint256 startTime = stakingData.updatedTime > 0
            ? stakingData.updatedTime
            : block.timestamp;

        uint256 endTime = block.timestamp;

        uint256 stakedDays = endTime > startTime
            ? (endTime - startTime) / (1 days)
            : 0;
        uint256 pendingReward = ((stakingData.balance * stakedDays * pool.APR) /
            ONE_YEAR) / 100;

        reward = pendingReward;
    }
}