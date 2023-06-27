// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../library/DSMath.sol";
import "../interfaces/IVeBids.sol";
import "../interfaces/IMasterBids.sol";
import "../interfaces/IRewarder.sol";

interface IVoter {
    function distribute(address _lpToken) external;
}

/// @title MasterBids
/// @notice MasterBids is a boss. He is not afraid of any snakes. In fact, he drinks their venoms. So, veBids holders boost
/// their (boosted) emissions. This contract rewards users in function of their amount of lp staked (base pool) factor (boosted pool)
/// Factor and sumOfFactors are updated by contract VeBids.sol after any veBids minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be safeTransferred to a governance smart contract once Bids is sufficiently
/// distributed and the community can show to govern itself.
/// @dev Updates:
/// - Compatible with gauge voting
contract MasterBids is Ownable, ReentrancyGuard, Pausable, IMasterBids {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 factor; // 20.18 fixed point. boosted factor = sqrt (lpAmount * veBids.balanceOf())
        // storage slot 2
        uint128 rewardDebt; // 20.18 fixed point. Reward debt. See explanation below.
        uint128 pendingBids; // 20.18 fixed point. Amount of pending Bids
        //
        // We do some fancy math here. Basically, any point in time, the amount of Bids
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accBidsPerShare + user.factor * pool.accBidsPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBidsPerShare`, `accBidsPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfoV3 {
        IERC20 lpToken; // Address of LP token contract.
        IRewarder rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accBidsPerShare; // 19.12 fixed point. Accumulated Bids per share, times 1e12.
        uint104 accBidsPerFactorShare; // 19.12 fixed point. Accumulated Bids per factor share
        uint40 lastRewardTimestamp;
    }

    uint256 public constant ACC_TOKEN_PRECISION = 1e12;

    // Bids token
    IERC20 public Bids;
    // Venom does not seem to hurt the Bids, it only makes it stronger.
    IVeBids public veBids;
    // New Master Bids address for future migrations
    IMasterBids public newMasterBids;
    // Address of Voter
    address public voter;
    //Dictates if voter has distribute function
    bool public voterIsCallable;
    // Base partition emissions (e.g. 300 for 30%).
    // BasePartition and boostedPartition add up to 1000 for 100%
    uint16 public basePartition;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet private lpTokens;
    // Info of each pool.
    PoolInfoV3[] public poolInfoV3;
    // userInfo[pid][user], Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Mapping of asset to pid. Offset by +1 to distinguish with default value
    mapping(address => uint256) internal assetPid;

    event Add(uint256 indexed pid, IERC20 indexed lpToken);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event SetRewarder(uint256 indexed pid, IRewarder rewarder);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionPartition(address indexed user, uint256 basePartition, uint256 boostedPartition);
    event UpdateVeBids(address indexed user, address oldVeBids, address newVeBids);
    event UpdateVoter(address indexed user, address oldVoter, address newVoter, bool callable);
    event EmergencyBidsWithdraw(address owner, uint256 balance);
    event NewMaster(address _newMaster);

    /// @dev Modifier ensuring that certain function can only be called by VeBids
    modifier onlyVeBids() {
        require(address(veBids) == msg.sender, "MasterBids: caller is not VeBids");
        _;
    }

    /// @dev Modifier ensuring that certain function can only be called by Voter
    modifier onlyVoter() {
        require(address(voter) == msg.sender, "MasterBids: caller is not Voter");
        _;
    }

    constructor(IERC20 _Bids, IVeBids _veBids, address _voter, uint16 _basePartition) {
        require(address(_Bids) != address(0), "Bids address cannot be zero");
        require(address(_veBids) != address(0), "VeBids address cannot be zero");
        require(_voter != address(0), "Voter address cannot be zero");
        require(_basePartition <= 1000, "base partition must be in range 0, 1000");

        Bids = _Bids;
        veBids = _veBids;
        voter = _voter;
        basePartition = _basePartition;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setNewMasterBids(IMasterBids _newMasterBids) external onlyOwner {
        newMasterBids = _newMasterBids;
        emit NewMaster(address(_newMasterBids));
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _lpToken the corresponding lp token
    /// @param _rewarder the contract that implements "onReward(user)" that is called on user operation
    function add(IERC20 _lpToken, IRewarder _rewarder) external onlyOwner {
        require(Address.isContract(address(_lpToken)), "add: LP token must be a valid contract");
        require(!lpTokens.contains(address(_lpToken)), "add: LP already added");

        // update PoolInfoV3 with the new LP
        poolInfoV3.push(
            PoolInfoV3({
                lpToken: _lpToken,
                rewarder: _rewarder,
                lastRewardTimestamp: uint40(block.timestamp),
                accBidsPerShare: 0,
                accBidsPerFactorShare: 0,
                sumOfFactors: 0,
                periodFinish: uint40(block.timestamp),
                rewardRate: 0
            })
        );
        assetPid[address(_lpToken)] = poolInfoV3.length;

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(poolInfoV3.length - 1, _lpToken);
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfoV3.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfoV3 storage pool = poolInfoV3[_pid];

        if (block.timestamp > pool.lastRewardTimestamp) {
            (uint256 accBidsPerShare, uint256 accBidsPerFactorShare) = calRewardPerUnit(_pid);
            pool.accBidsPerShare = to104(accBidsPerShare);
            pool.accBidsPerFactorShare = to104(accBidsPerFactorShare);
            pool.lastRewardTimestamp = uint40(lastTimeRewardApplicable(pool.periodFinish));
        }

        // We can consider to skip this function to minimize gas
        if (voterIsCallable) {
            IVoter(voter).distribute(address(pool.lpToken));
        }
    }

    /// @dev Refer to synthetix/StakingRewards.sol notifyRewardAmount
    /// Note: This looks safe from reentrancy.
    function notifyRewardAmount(address _lpToken, uint256 _amount, uint256 _rewardDuration) external override onlyVoter {
        require(_amount > 0, "notifyRewardAmount: zero amount");

        // this line reverts if asset is not in the list
        uint256 pid = assetPid[_lpToken] - 1;
        PoolInfoV3 storage pool = poolInfoV3[pid];
        if (pool.lastRewardTimestamp >= pool.periodFinish) {
            pool.rewardRate = to128(_amount / _rewardDuration);
        } else {
            uint256 remainingTime = pool.periodFinish - pool.lastRewardTimestamp;
            uint256 leftoverReward = remainingTime * pool.rewardRate;
            pool.rewardRate = to128((_amount + leftoverReward) / _rewardDuration);
        }

        pool.lastRewardTimestamp = uint40(block.timestamp);
        pool.periodFinish = uint40(block.timestamp + _rewardDuration);

        // Event is not emitted as Voter should have already emitted it
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterBids.
    /// @notice user must initiate transaction from masterbids
    /// @dev Assume the original MasterBids has stopped emissions
    /// hence we skip IVoter(voter).distribute() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterBids) != (address(0)), "to where?");

        _multiClaim(_pids);
        for (uint256 i; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfoV3 storage pool = poolInfoV3[pid];
                pool.lpToken.approve(address(newMasterBids), user.amount);
                uint256 newPid = newMasterBids.getAssetPid(address(pool.lpToken));
                newMasterBids.depositFor(newPid, user.amount, msg.sender);

                pool.sumOfFactors -= user.factor;
                // remove user
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to masterbids for Bids allocation on behalf of user
    /// @dev user must initiate transaction from masterbids
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(uint256 _pid, uint256 _amount, address _user) external override nonReentrant whenNotPaused {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        _updatePool(_pid);

        _updateUserAmount(_pid, _user, user.amount + _amount);

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to masterbids for Bids allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant whenNotPaused returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // update pool in case user has deposited
        _updatePool(_pid);

        (reward, additionalRewards) = _updateUserAmount(_pid, msg.sender, user.amount + _amount);


        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(
        uint256[] calldata _pids
    )
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory amounts, uint256[][] memory additionalRewards)
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(
        uint256[] memory _pids
    ) private returns (uint256 reward, uint256[] memory amounts, uint256[][] memory additionalRewards) {
        // accumulate rewards for each one of the pids in pending
        amounts = new uint256[](_pids.length);
        additionalRewards = new uint256[][](_pids.length);
        for (uint256 i; i < _pids.length; ++i) {
            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            _updatePool(_pids[i]);

            if (user.amount > 0) {
                PoolInfoV3 storage pool = poolInfoV3[_pids[i]];
                // increase pending to send all rewards once
                uint256 poolRewards = ((uint256(user.amount) *
                    pool.accBidsPerShare +
                    uint256(user.factor) *
                    pool.accBidsPerFactorShare) / ACC_TOKEN_PRECISION) +
                    user.pendingBids -
                    user.rewardDebt;

                user.pendingBids = 0;

                // update reward debt
                user.rewardDebt = to128(
                    (uint256(user.amount) * pool.accBidsPerShare + uint256(user.factor) * pool.accBidsPerFactorShare) /
                        ACC_TOKEN_PRECISION
                );

                // increase reward
                reward += poolRewards;

                amounts[i] = poolRewards;
                emit Harvest(msg.sender, _pids[i], amounts[i]);

                // if exist, update external rewarder
                IRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onReward(msg.sender);
                }
            }
        }

        // safeTransfer all rewards
        Bids.safeTransfer(payable(msg.sender), reward);
    }

    /// @notice Withdraw LP tokens from MasterBids.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) external override nonReentrant whenNotPaused returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not enough balance");

        _updatePool(_pid);

        (reward, additionalRewards) = _updateUserAmount(_pid, msg.sender, user.amount - _amount);

        pool.lpToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Update user balance and distribute Bids rewards
    function _updateUserAmount(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // Harvest Bids
        if (user.amount > 0 || user.pendingBids > 0) {
            reward =
                ((uint256(user.amount) * pool.accBidsPerShare + uint256(user.factor) * pool.accBidsPerFactorShare) /
                    ACC_TOKEN_PRECISION) +
                user.pendingBids -
                user.rewardDebt;
            user.pendingBids = 0;

            Bids.safeTransfer(payable(_user), reward);
            emit Harvest(_user, _pid, reward);
        }

        // update amount of lp staked
        user.amount = to128(_amount);

        // update sumOfFactors
        uint128 oldFactor = user.factor;
        user.factor = to128(DSMath.sqrt(user.amount * veBids.balanceOf(_user), user.amount));

        // update reward debt
        user.rewardDebt = to128(
            (uint256(user.amount) * pool.accBidsPerShare + uint256(user.factor) * pool.accBidsPerFactorShare) / ACC_TOKEN_PRECISION
        );

        // claim reward before we update factors (Due to rewarder ratios being based on masters rewards)
        IRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onReward(_user);
        }

        pool.sumOfFactors = to128(pool.sumOfFactors + user.factor - oldFactor);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) external override nonReentrant {
        PoolInfoV3 storage pool = poolInfoV3[_pid];

        UserInfo storage user = userInfo[_pid][msg.sender];

        pool.lpToken.safeTransfer(address(msg.sender), user.amount);

        pool.sumOfFactors = pool.sumOfFactors - user.factor;

        user.amount = 0;
        user.factor = 0;
        user.rewardDebt = 0;

        IRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(msg.sender);
        }

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice updates emission partition
    /// @param _basePartition the future base partition
    function updateEmissionPartition(uint16 _basePartition) external onlyOwner {
        require(_basePartition <= 1000);
        massUpdatePools();
        basePartition = _basePartition;
        emit UpdateEmissionPartition(msg.sender, _basePartition, 1000 - _basePartition);
    }

    /// @notice updates veBids address
    /// @param _newVeBids the new VeBids address
    function setVeBids(IVeBids _newVeBids) external onlyOwner {
        require(address(_newVeBids) != address(0));
        IVeBids oldVeBids = veBids;
        veBids = _newVeBids;
        emit UpdateVeBids(msg.sender, address(oldVeBids), address(_newVeBids));
    }

    /// @notice updates voter address
    /// @param _newVoter the new Voter address
    function setVoter(address _newVoter, bool _voterIsCallable) external onlyOwner {
        // voter address can be zero during a migration. This is done to avoid
        // the scenario where both old and new MasterBids claims in migrate,
        // which calls voter.distribute. But only one can succeed as voter.distribute
        // is only callable from gauge manager.
        require(_newVoter != address(0), "Voter address cannot be zero");
        address oldVoter = voter;
        voter = _newVoter;
        voterIsCallable = _voterIsCallable;
        emit UpdateVoter(msg.sender, oldVoter, _newVoter, _voterIsCallable);
    }

    /// @notice updates factor after any veBids token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVeBidsBalance the amount of veBids
    /// @dev can only be called by veBids
    function updateFactor(address _user, uint256 _newVeBidsBalance) external override onlyVeBids {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfoV3.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount == 0) {
                continue;
            }

            // first, update pool
            _updatePool(pid);
            PoolInfoV3 storage pool = poolInfoV3[pid];

            // calculate pending
            uint256 pending = ((uint256(user.amount) * pool.accBidsPerShare + uint256(user.factor) * pool.accBidsPerFactorShare) /
                ACC_TOKEN_PRECISION) - user.rewardDebt;
            // increase pendingBids
            user.pendingBids += to128(pending);

            // update boosted partition factor
            uint256 oldFactor = user.factor;
            uint256 newFactor = DSMath.sqrt(user.amount * _newVeBidsBalance, user.amount);
            user.factor = to128(newFactor);
            // update reward debt, take into account newFactor
            user.rewardDebt = to128(
                (uint256(user.amount) * pool.accBidsPerShare + newFactor * pool.accBidsPerFactorShare) / ACC_TOKEN_PRECISION
            );
            // also, update sumOfFactors
            pool.sumOfFactors = to128(pool.sumOfFactors + newFactor - oldFactor);
        }
    }

    /// @notice In case we need to manually migrate Bids funds from masterbids
    /// Sends all remaining Bids from the contract to the owner
    function emergencyBidsWithdraw() external onlyOwner {

        Bids.safeTransfer(address(msg.sender), Bids.balanceOf(address(this)));
        emit EmergencyBidsWithdraw(address(msg.sender), Bids.balanceOf(address(this)));
    }

    function boostedPartition() external view returns (uint256) {
        return 1000 - basePartition;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfoV3.length;
    }

    function getAssetPid(address asset) external view override returns (uint256) {
        // revert if asset not exist
        return assetPid[asset] - 1;
    }

    function lastTimeRewardApplicable(uint256 _periodFinish) public view returns (uint256) {
        return block.timestamp < _periodFinish ? block.timestamp : _periodFinish;
    }

    function calRewardPerUnit(uint256 _pid) public view returns (uint256 accBidsPerShare, uint256 accBidsPerFactorShare) {
        PoolInfoV3 storage pool = poolInfoV3[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        accBidsPerShare = pool.accBidsPerShare;
        accBidsPerFactorShare = pool.accBidsPerFactorShare;

        if (lpSupply == 0 || block.timestamp <= pool.lastRewardTimestamp) {
            // update only if now > lastRewardTimestamp
            return (accBidsPerShare, accBidsPerFactorShare);
        }

        uint256 secondsElapsed = lastTimeRewardApplicable(pool.periodFinish) - pool.lastRewardTimestamp;
        uint256 BidsReward = secondsElapsed * pool.rewardRate;
        accBidsPerShare += (BidsReward * ACC_TOKEN_PRECISION * basePartition) / (lpSupply * 1000);

        if (pool.sumOfFactors != 0) {
            accBidsPerFactorShare += (BidsReward * ACC_TOKEN_PRECISION * (1000 - basePartition)) / (pool.sumOfFactors * 1000);
        }
    }

    /// @notice View function to see pending Bids on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(
        uint256 _pid,
        address _user
    ) external view override returns (uint256 pendingRewards, uint256[] memory pendingRewarderRewards) {
        PoolInfoV3 memory pool = poolInfoV3[_pid];

        // calculate accBidsPerShare and accBidsPerFactorShare
        (uint256 accBidsPerShare, uint256 accBidsPerFactorShare) = calRewardPerUnit(_pid);

        UserInfo memory user = userInfo[_pid][_user];
        pendingRewards =
            ((user.amount * accBidsPerShare + user.factor * accBidsPerFactorShare) / ACC_TOKEN_PRECISION) +
            user.pendingBids -
            user.rewardDebt;

        // Rewarder tokens
        if (address(pool.rewarder) != address(0)) {
            pendingRewarderRewards = pool.rewarder.pendingTokens(_user);
        }
    }

    //For accurate pending Bids use pendingTokens instead.
    /// @notice View function to see pending Bids with factor and base separated.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokensSplit(
        uint256 _pid,
        address _user
    ) external view returns (uint256 pendingBaseRewards, uint256 pendingFactorRewards, uint256[] memory pendingRewarderRewards) {
        PoolInfoV3 memory pool = poolInfoV3[_pid];

        // calculate accBidsPerShare and accBidsPerFactorShare
        (uint256 accBidsPerShare, uint256 accBidsPerFactorShare) = calRewardPerUnit(_pid);

        UserInfo memory user = userInfo[_pid][_user];
        // Rewarder tokens
        if (address(pool.rewarder) != address(0)) {
            pendingRewarderRewards = pool.rewarder.pendingTokens(_user);
        }
        if (user.amount == 0) {
            return (0, 0, pendingRewarderRewards);
        }

        ////Working
        uint256 pendingBaseRewardsHigh = user.amount * accBidsPerShare;
        uint256 pendingFactorRewardsHigh = user.factor * accBidsPerFactorShare;
        uint256 pendingRewards = ((pendingBaseRewardsHigh + pendingFactorRewardsHigh) / ACC_TOKEN_PRECISION) +
            user.pendingBids -
            user.rewardDebt;

        pendingFactorRewards = (pendingRewards * pendingFactorRewardsHigh / (pendingBaseRewardsHigh + pendingFactorRewardsHigh));
        pendingBaseRewards = pendingRewards - pendingFactorRewards;
    }

    function to128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert("uint128 overflow");
        return uint128(val);
    }

    function to104(uint256 val) internal pure returns (uint104) {
        if (val > type(uint104).max) revert("uint104 overflow");
        return uint104(val);
    }

    /// @notice Update the given pool's rewarder
    /// @param _pid the pool id
    /// @param _rewarder the rewarder
    function setRewarder(uint256 _pid, IRewarder _rewarder) external onlyOwner {
        require(Address.isContract(address(_rewarder)) || address(_rewarder) == address(0), "set: rewarder must be contract or zero");

        PoolInfoV3 storage pool = poolInfoV3[_pid];

        pool.rewarder = _rewarder;
        emit SetRewarder(_pid, _rewarder);
    }
}