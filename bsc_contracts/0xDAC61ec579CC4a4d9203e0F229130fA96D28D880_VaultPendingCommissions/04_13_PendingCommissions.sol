// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPendingCommissions.sol";
import "./interfaces/IGymMLMQualifications.sol";
import "./RewardRateConfigurable.sol";

contract PendingCommissions is
    IPendingCommissions,
    Initializable,
    ReentrancyGuardUpgradeable,
    RewardRateConfigurable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Info of each pool
     * @param allocPoint: How many allocation points assigned to this pool. GYM to distribute per block
     * @param lastRewardBlock: Last block number that reward distribution occurs
     * @param accUTacoPerShare: Accumulated rewardPool per share, times 1e18
     */
    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 sharesTotal;
        uint256 totalClaims;
    }

    /**
     * @notice Info of each user
     * @param userRewards: array of user rewards by level
     * @param userRewardDebt: array of user debt rewards by level
     * @param totalClaims: user totalClaims
     */
    struct UserRewardsInfo {
        uint256[25] userRewards;
        uint256 userRewardDebt;
        uint256 totalClaims;
    }

    /// Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    /// Startblock number
    uint256 public startBlock;
    /// Info of each pool.
    PoolInfo[] public poolInfo;

    address public mlmAddress;
    address public mlmQualificationsAddress;
    address public rewardToken;

    mapping(uint256 => mapping(address => UserRewardsInfo)) private userRewardsInfo;
    mapping(uint256 => mapping(address => uint256)) public partnersClaimRewards;
    address private constant GLOBAL_COMMISSION_ADDRESS =0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB;
    /* ========== EVENTS ========== */

    event RewardPaid(address indexed token, address indexed user, uint256 amount);

    function __PendingCommissions_init(
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval,
        address _mlmAddress,
        address _rewardToken,
        address _mlmQualificationsAddress
    ) internal onlyInitializing {
        require(
            block.number < _startBlock,
            "PendingCommissions: Start block must have a bigger value"
        );
        startBlock = _startBlock;
        mlmAddress = _mlmAddress;
        rewardToken = _rewardToken;
        mlmQualificationsAddress = _mlmQualificationsAddress;

        __ReentrancyGuard_init();
        __RewardRateConfigurable_init(_rewardPerBlock, _rewardUpdateBlocksInterval);
    }

    modifier onlyMLM() {
        require(
            msg.sender == mlmAddress,
            "PendingCommissions:: Only MLM contract can call the method"
        );
        _;
    }

    modifier onlyWithInvestment(address _user) virtual {
        _;
    }

    function updateRewards(
        uint256 _pid,
        bool _isDeposit,
        uint256 _totalAmount,
        DistributionInfo[] memory _distributionInfo
    ) public onlyMLM  {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        if (_isDeposit) {
            pool.sharesTotal += _totalAmount * 39 / 100;
        }else{
            pool.sharesTotal -= _totalAmount * 39 / 100;
        }
        for (uint256 i = 0; i < _distributionInfo.length; ++i) {
            uint256[25] storage _userRewards = userRewardsInfo[_pid][_distributionInfo[i].user].userRewards;

             uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(_distributionInfo[i].user);
            (uint256 userSharesByTotal,uint256 userSharesByLevel) = _getUserShares(_pid, _level, _distributionInfo[i].user);
            if(userSharesByTotal != 0 && userSharesByLevel != 0) {
                 _claimInternally(_pid , _distributionInfo[i].user, userSharesByTotal, userSharesByLevel);
            }
           
            if (_isDeposit) {
                _userRewards[i] += _distributionInfo[i].amount;
                userSharesByTotal += _distributionInfo[i].amount;
            } else {
                if(_userRewards[i] < _distributionInfo[i].amount) {
                    _userRewards[i] = 0;
                }else{
                    _userRewards[i] -= _distributionInfo[i].amount;
                }
                if(userSharesByTotal < _distributionInfo[i].amount) {
                    userSharesByTotal = 0;
                }else {
                    userSharesByTotal -= _distributionInfo[i].amount;
                }
            }

            userRewardsInfo[_pid][_distributionInfo[i].user].userRewardDebt = (userSharesByTotal * poolInfo[_pid].accRewardPerShare) / 1e18;
           
        }

    }
    function claimInternally(uint256 _pid,address _user) public nonReentrant{
        updatePool(_pid);
        uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(_user);
        (uint256 userSharesByTotal,uint256 userSharesByLevel) = _getUserShares(_pid, _level, _user);
        _claimInternally(_pid,_user,userSharesByTotal,userSharesByLevel);
    }

    function _claimInternally(uint256 _pid,address _user,uint256 userSharesByTotal,uint256 userSharesByLevel) private {
        uint256 userTotalRewards = (userSharesByTotal * poolInfo[_pid].accRewardPerShare) / 1e18 - userRewardsInfo[_pid][_user].userRewardDebt;
        uint256 userActiveRewardsPercent = 0;
        if(userTotalRewards > 0) {
            userActiveRewardsPercent = (userSharesByLevel * 1e18 ) / userSharesByTotal;
        }

        partnersClaimRewards[_pid][_user] +=( userTotalRewards * userActiveRewardsPercent) / 1e18;
        userRewardsInfo[_pid][_user].userRewardDebt = (userSharesByTotal * poolInfo[_pid].accRewardPerShare) / 1e18;
        partnersClaimRewards[_pid][GLOBAL_COMMISSION_ADDRESS] += userTotalRewards - (( userTotalRewards * userActiveRewardsPercent) / 1e18);
    }

    function userRewardDebt(uint256 _pid,address _user) public view returns(uint256){
        return userRewardsInfo[_pid][_user].userRewardDebt;
    }
    
    /**
     * @notice Claim users rewards from given pool
     * @param _pid pool Id
     */
    function claim(uint256 _pid) public nonReentrant {
        updatePool(_pid);
        uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(
            msg.sender
        );
        _claim(_pid, _level, msg.sender);
    }

    /**
     * @notice Claim users rewards from all pools
     */
    function claimAll() public nonReentrant {
        uint256 length = getPoolLength();
        uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(
            msg.sender
        );
        massUpdatePools();

        for (uint256 _pid = 0; _pid < length; ++_pid) {
            _claim(_pid, _level, msg.sender);
        }
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _pid: Pool id where user has assets
     * @param _user: Users address
     */
    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(_user);
        return _getPendingRewards(_pid, _level, _user);
    }

    /**
     * @notice View function to see total claims on frontend.
     * @param _pid: Pool id where user has assets
     * @param _user: Users address
     */
    function getUserTotalClaims(uint256 _pid, address _user) public view returns (uint256) {
        return userRewardsInfo[_pid][_user].totalClaims;
    }

    /**
     * @notice View function to get user shares
     * @param _pid: pool id
     * @param _user: Users address
     */
    function getUserShares(uint256 _pid, address _user) public view returns (uint256,uint256) {
        uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(_user);
        return _getUserShares(_pid, _level, _user);
    }

    /**
     * @notice View function to get all pending
     * @param _user: Users address
     */
    function getPendingRewardTotal(address _user) public view returns (uint256) {
        uint256 rewards;
        uint256 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(_user);
        for (uint256 _pid = 0; _pid < getPoolLength(); ++_pid) {
            rewards += _getPendingRewards(_pid, _level, _user);
        }
        return rewards;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid: Pool id that will be updated
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardBlock;
        if (multiplier <= 0) {
            return;
        }
        uint256 _rewardPerBlock = getRewardPerBlock();
        uint256 _reward = (multiplier * _rewardPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accRewardPerShare = pool.accRewardPerShare + ((_reward * 1e18) / pool.sharesTotal);
        pool.lastRewardBlock = block.number;

        // Update rewardPerBlock AFTER pool was updated
        _updateRewardPerBlock();
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = getPoolLength();
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function getPoolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice  Safe transfer function for reward tokens
     * @param _rewardToken Address of reward token contract
     * @param _to Address of receiver
     * @param _amount Amount of reward tokens to transfer
     */
    function _safeRewardTransfer(
        address _rewardToken,
        address _to,
        uint256 _amount
    ) private {
        uint256 _bal = IERC20Upgradeable(_rewardToken).balanceOf(address(this));
        uint256 amountToTransfer = _amount > _bal ? _bal : _amount;

        IERC20Upgradeable(_rewardToken).safeTransfer(_to, amountToTransfer);
    }

    /**
     * @notice Calculates amount of reward user will get.
     * @param _pid: Pool id
     */
    function _claim(
        uint256 _pid,
        uint256 _level,
        address _user
    ) private {
        PoolInfo storage pool = poolInfo[_pid];
        if(_user == GLOBAL_COMMISSION_ADDRESS) {
            _level = 24;
        }
        (uint256 userSharesByTotal,uint256 userSharesByLevel) = _getUserShares(_pid, _level, _user);

        uint256 userTotalRewards = (userSharesByTotal * poolInfo[_pid].accRewardPerShare) / 1e18 - userRewardsInfo[_pid][_user].userRewardDebt;
        uint256 userActiveRewardsPercent = 0;
        if(userTotalRewards > 0) {
            userActiveRewardsPercent = (userSharesByLevel * 1e18 ) / userSharesByTotal;
        }

        uint256 _rewards = ( ( userTotalRewards * userActiveRewardsPercent) / 1e18);

        if (_rewards > 0 || partnersClaimRewards[_pid][_user] > 0) {
            _safeRewardTransfer(rewardToken, _user, _rewards + partnersClaimRewards[_pid][_user]);
            emit RewardPaid(rewardToken, _user, _rewards+ partnersClaimRewards[_pid][_user]);

            UserRewardsInfo storage _userRewardsInfo = userRewardsInfo[_pid][_user];
            _userRewardsInfo.totalClaims += (_rewards+ partnersClaimRewards[_pid][_user]);

            pool.totalClaims += (_rewards+ partnersClaimRewards[_pid][_user]);

            userRewardsInfo[_pid][_user].userRewardDebt = (userSharesByTotal * pool.accRewardPerShare) / 1e18;

            partnersClaimRewards[_pid][GLOBAL_COMMISSION_ADDRESS] += userTotalRewards - _rewards;

            partnersClaimRewards[_pid][_user] = 0;

        }
    }

    function _getUserShares(
        uint256 _pid,
        uint256 _level,
        address _user
    ) private view returns (uint256 _userShares,uint256 _sharesByLevel) {
        uint256[25] memory _userRewards = userRewardsInfo[_pid][_user].userRewards;
        for (uint256 i = 0; i <= 24; ++i) {
            _userShares += _userRewards[i];
            if(i == _level) {
            _sharesByLevel = _userShares;
            }
        }
    }

    function _getPendingRewards(
        uint256 _pid,
        uint256 _level,
        address _user
    ) private view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        if (block.number > pool.lastRewardBlock && pool.sharesTotal != 0) {
            uint256 _multiplier = block.number - pool.lastRewardBlock;
            uint256 _reward = (_multiplier * getRewardPerBlock() * pool.allocPoint) /
                totalAllocPoint;
            _accRewardPerShare = _accRewardPerShare + ((_reward * 1e18) / pool.sharesTotal);
        }

        (uint256 userSharesByTotal,uint256 userSharesByLevel) = _getUserShares(_pid, _level, _user);

        uint256 userTotalRewards = (userSharesByTotal * _accRewardPerShare) / 1e18 - userRewardsInfo[_pid][_user].userRewardDebt;
        uint256 userActiveRewardsPercent = 0;
        if(userTotalRewards > 0) {
            userActiveRewardsPercent = (userSharesByLevel * 1e18 ) / userSharesByTotal;
        }
        
        
        return
           ( ( userTotalRewards * userActiveRewardsPercent) / 1e18 ) + partnersClaimRewards[_pid][_user];
    }

}