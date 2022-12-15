// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libraries/Math.sol";
import "./interfaces/IVeOh.sol";
import "./interfaces/IOh.sol";
import "./interfaces/IMasterOh.sol";
import "./interfaces/IRewarder.sol";

/// MasterOh is a boss. He says "go f your blocks maki boy, I'm gonna use timestamp instead"
/// In addition, he feeds himself from Vote-Escrowed Oh. So, veOh holders boost their (non-diluting) emissions.
/// This contract rewards users in function of their amount of lp staked (diluting pool) factor (non-diluting pool)
/// Factor and sumOfFactors are updated by contract VeOh.sol after any veOh minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Oh is sufficiently
/// distributed and the community can show to govern itself.
contract MasterOh is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, IMasterOh {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 factor; // non-diluting factor = sqrt (lpAmount * veOh.balanceOf())
        //
        // We do some fancy math here. Basically, any point in time, the amount of OHs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accOhPerShare`, `accOhPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. OHs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that OHs distribution occurs.
        uint256 accOhPerShare; // Accumulated OHs per share, times 1e12.
        IRewarder rewarder;
        uint256 sumOfFactors; // the sum of all non diluting factors by all of the users in the pool
        uint256 accOhPerFactorShare; // accumulated oh per factor share
    }

    // The strongest oh out there (oh token).
    IERC20 public oh;
    // The strongest vote-escrowed oh out there (veOh token)
    IVeOh public veOh;
    // New Master Oh address for future migrations
    IMasterOh newMasterOh;
    // OH tokens created per second.
    uint256 public ohPerSec;
    // Emissions: both must add to 1000 => 100%
    // Diluting emissions partition (e.g. 300 for 30%)
    uint256 public dilutingPartition;
    // Non-diluting emissions partition (e.g. 500 for 50%)
    uint256 public nonDilutingPartition;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when OH mining starts.
    uint256 public startTimestamp;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet private lpTokens;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Amount of claimable oh the user has
    mapping(uint256 => mapping(address => uint256)) public claimableOh;

    event Add(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event Set(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accOhPerShare);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 ohPerSec);
    event UpdateEmissionPartition(address indexed user, uint256 dilutingPartition, uint256 nonDilutingPartition);
    event UpdateVeOh(address indexed user, address oldVeOh, address newVeOh);

    /// @dev Modifier ensuring that certain function can only be called by VeOh
    modifier onlyVeOh() {
        require(address(veOh) == msg.sender, "notVeOh: wut?");
        _;
    }

    function initialize(
        IERC20 _oh,
        IVeOh _veOh,
        uint256 _ohPerSec,
        uint256 _dilutingPartition,
        uint256 _startTimestamp
    ) external initializer {
        require(address(_oh) != address(0), "oh address cannot be zero");
        require(address(_veOh) != address(0), "veOh address cannot be zero");
        require(_dilutingPartition <= 1000, "diluting partition must be in range 0, 1000");

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        oh = _oh;
        veOh = _veOh;
        ohPerSec = _ohPerSec;
        dilutingPartition = _dilutingPartition;
        nonDilutingPartition = 1000 - _dilutingPartition;
        startTimestamp = _startTimestamp;
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

    function setNewMasterOh(IMasterOh _newMasterOh) external onlyOwner {
        newMasterOh = _newMasterOh;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _allocPoint allocation points for this LP
    /// @param _lpToken the corresponding lp token
    /// @param _rewarder the rewarder
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder
    ) public onlyOwner {
        require(Address.isContract(address(_lpToken)), "add: LP token must be a valid contract");
        require(Address.isContract(address(_rewarder)) || address(_rewarder) == address(0), "add: rewarder must be contract or zero");
        require(!lpTokens.contains(address(_lpToken)), "add: LP already added");

        // update all pools
        massUpdatePools();

        // update last time rewards were calculated to now
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;

        // add _allocPoint to total alloc points
        totalAllocPoint = totalAllocPoint + _allocPoint;

        // update PoolInfo with the new LP
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accOhPerShare: 0,
                rewarder: _rewarder,
                sumOfFactors: 0,
                accOhPerFactorShare: 0
            })
        );

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(poolInfo.length - 1, _allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's OH allocation point. Can only be called by the owner.
    /// @param _pid the pool id
    /// @param _allocPoint allocation points
    /// @param _rewarder the rewarder
    /// @param overwrite overwrite rewarder?
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite
    ) public onlyOwner {
        require(Address.isContract(address(_rewarder)) || address(_rewarder) == address(0), "set: rewarder must be contract or zero");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (overwrite) {
            poolInfo[_pid].rewarder = _rewarder;
        }
        emit Set(_pid, _allocPoint, overwrite ? _rewarder : poolInfo[_pid].rewarder, overwrite);
    }

    /// @notice View function to see pending OHs on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    /// TODO include factor operations
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        override
        returns (
            uint256 pendingOh,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOhPerShare = pool.accOhPerShare;
        uint256 accOhPerFactorShare = pool.accOhPerFactorShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;
            uint256 ohReward = (secondsElapsed * ohPerSec * pool.allocPoint) / totalAllocPoint;
            accOhPerShare += (ohReward * 1e12 * dilutingPartition) / (lpSupply * 1000);
            if (pool.sumOfFactors != 0) {
                accOhPerFactorShare += (ohReward * 1e12 * nonDilutingPartition) / (pool.sumOfFactors * 1000);
            }
        }
        pendingOh = ((user.amount * accOhPerShare + user.factor * accOhPerFactorShare) / 1e12) + claimableOh[_pid][_user] - user.rewardDebt;
        // If it's a double reward farm, we return info about the bonus token
        if (address(pool.rewarder) != address(0)) {
            (bonusTokenAddress, bonusTokenSymbol) = rewarderBonusTokenInfo(_pid);
            pendingBonusToken = pool.rewarder.pendingTokens(_user);
        }
    }

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(uint256 _pid) public view override returns (address bonusTokenAddress, string memory bonusTokenSymbol) {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) != address(0)) {
            bonusTokenAddress = address(pool.rewarder.rewardToken());
            bonusTokenSymbol = IERC20Metadata(address(pool.rewarder.rewardToken())).symbol();
        }
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        // update only if now > last time we updated rewards
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));

            // if balance of lp supply is 0, update lastRewardTime and quit function
            if (lpSupply == 0) {
                pool.lastRewardTimestamp = block.timestamp;
                return;
            }
            // calculate seconds elapsed since last update
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;

            // calculate oh reward
            uint256 ohReward = (secondsElapsed * ohPerSec * pool.allocPoint) / totalAllocPoint;

            // update accOhPerShare to reflect diluting rewards
            pool.accOhPerShare += (ohReward * 1e12 * dilutingPartition) / (lpSupply * 1000);

            // update accOhPerFactorShare to reflect non-diluting rewards
            if (pool.sumOfFactors == 0) {
                pool.accOhPerFactorShare = 0;
            } else {
                pool.accOhPerFactorShare += (ohReward * 1e12 * nonDilutingPartition) / (pool.sumOfFactors * 1000);
            }

            // update lastRewardTimestamp to now
            pool.lastRewardTimestamp = block.timestamp;
            emit UpdatePool(_pid, pool.lastRewardTimestamp, lpSupply, pool.accOhPerShare);
        }
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterOh.
    /// @notice user must initiate transaction from masterchef
    /// @dev Assume the orginal MasterOh has stopped emisions
    /// hence we can skip updatePool() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterOh) != (address(0)), "to where?");

        _multiClaim(_pids);
        for (uint256 i = 0; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];
                pool.lpToken.approve(address(newMasterOh), user.amount);
                newMasterOh.depositFor(pid, user.amount, msg.sender);

                pool.sumOfFactors -= user.factor;
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to MasterChef for OH allocation on behalf of user
    /// @dev user must initiate transaction from masterchef
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external override nonReentrant whenNotPaused {
        require(tx.origin == _user, "depositFor: wut?");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        _updatePool(_pid);
        if (user.amount > 0) {
            // Harvest OH
            uint256 pending = ((user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12) +
                claimableOh[_pid][msg.sender] -
                user.rewardDebt;
            claimableOh[_pid][msg.sender] = 0;

            pending = safeOhTransfer(payable(_user), pending);
            emit Harvest(_user, _pid, pending);
        }

        // update amount of lp staked by user
        user.amount += _amount;

        // update non-diluting factor
        uint256 oldFactor = user.factor;
        user.factor = Math.sqrt(user.amount * veOh.balanceOf(_user));
        pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(_user, user.amount);
        }

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for OH allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(uint256 _pid, uint256 _amount) external override nonReentrant whenNotPaused returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        uint256 pending;
        if (user.amount > 0) {
            // Harvest OH
            pending =
                ((user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12) +
                claimableOh[_pid][msg.sender] -
                user.rewardDebt;
            claimableOh[_pid][msg.sender] = 0;

            pending = safeOhTransfer(payable(msg.sender), pending);
            emit Harvest(msg.sender, _pid, pending);
        }

        // update amount of lp staked by user
        user.amount += _amount;

        // update non-diluting factor
        uint256 oldFactor = user.factor;
        user.factor = Math.sqrt(user.amount * veOh.balanceOf(msg.sender));
        pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        uint256 additionalRewards;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onReward(msg.sender, user.amount);
        }

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
        return (pending, additionalRewards);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(uint256[] memory _pids)
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(uint256[] memory _pids)
        private
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        // accumulate rewards for each one of the pids in pending
        uint256 pending;
        uint256[] memory amounts = new uint256[](_pids.length);
        uint256[] memory additionalRewards = new uint256[](_pids.length);
        for (uint256 i = 0; i < _pids.length; ++i) {
            _updatePool(_pids[i]);
            PoolInfo storage pool = poolInfo[_pids[i]];
            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            if (user.amount > 0) {
                // increase pending to send all rewards once
                uint256 poolRewards = ((user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12) +
                    claimableOh[_pids[i]][msg.sender] -
                    user.rewardDebt;

                claimableOh[_pids[i]][msg.sender] = 0;

                // update reward debt
                user.rewardDebt = (user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12;

                // increase pending
                pending += poolRewards;

                amounts[i] = poolRewards;
                // if existant, get external rewarder rewards for pool
                IRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onReward(msg.sender, user.amount);
                }
            }
        }
        // transfer all remaining rewards
        uint256 transfered = safeOhTransfer(payable(msg.sender), pending);
        if (transfered != pending) {
            for (uint256 i = 0; i < _pids.length; ++i) {
                amounts[i] = (transfered * amounts[i]) / pending;
                emit Harvest(msg.sender, _pids[i], amounts[i]);
            }
        } else {
            for (uint256 i = 0; i < _pids.length; ++i) {
                // emit event for pool
                emit Harvest(msg.sender, _pids[i], amounts[i]);
            }
        }

        return (transfered, amounts, additionalRewards);
    }

    /// @notice Withdraw LP tokens from MasterOh.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external override nonReentrant whenNotPaused returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        _updatePool(_pid);

        // Harvest OH
        uint256 pending = ((user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12) +
            claimableOh[_pid][msg.sender] -
            user.rewardDebt;
        claimableOh[_pid][msg.sender] = 0;

        pending = safeOhTransfer(payable(msg.sender), pending);
        emit Harvest(msg.sender, _pid, pending);

        // for non-diluting factor
        uint256 oldFactor = user.factor;

        // update amount of lp staked
        user.amount = user.amount - _amount;

        // update non-diluting factor
        user.factor = Math.sqrt(user.amount * veOh.balanceOf(msg.sender));
        pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        uint256 additionalRewards = 0;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onReward(msg.sender, user.amount);
        }

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        return (pending, additionalRewards);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);

        // update non-diluting factor
        pool.sumOfFactors = pool.sumOfFactors - user.factor;
        user.factor = 0;

        // update diluting factors
        user.amount = 0;
        user.rewardDebt = 0;

        // reset rewarder
        IRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(msg.sender, 0);
        }

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice Safe oh transfer function, just in case if rounding error causes pool to not have enough OHs.
    /// @param _to beneficiary
    /// @param _amount the amount to transfer
    function safeOhTransfer(address payable _to, uint256 _amount) private returns (uint256) {
        uint256 ohBal = oh.balanceOf(address(this));

        // perform additional check in case there are no more oh tokens to distribute.
        // emergency withdraw would be necessary
        require(ohBal > 0, "No tokens to distribute");

        if (_amount > ohBal) {
            oh.transfer(_to, ohBal);
            return ohBal;
        } else {
            oh.transfer(_to, _amount);
            return _amount;
        }
    }

    /// @notice updates emission rate
    /// @param _ohPerSec oh amount to be updated
    /// @dev Pancake has to add hidden dummy pools inorder to alter the emission,
    /// @dev here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _ohPerSec) external onlyOwner {
        massUpdatePools();
        ohPerSec = _ohPerSec;
        emit UpdateEmissionRate(msg.sender, _ohPerSec);
    }

    /// @notice updates emission partition
    /// @param _dilutingPartition the future diluting partition
    function updateEmissionPartition(uint256 _dilutingPartition) external onlyOwner {
        require(_dilutingPartition <= 1000);
        massUpdatePools();
        dilutingPartition = _dilutingPartition;
        nonDilutingPartition = 1000 - _dilutingPartition;
        emit UpdateEmissionPartition(msg.sender, _dilutingPartition, 1000 - _dilutingPartition);
    }

    /// @notice updates veOh address
    /// @param _newVeOh the new VeOh address
    function setVeOh(IVeOh _newVeOh) external onlyOwner {
        require(address(_newVeOh) != address(0));
        massUpdatePools();
        IVeOh oldVeOh = veOh;
        veOh = _newVeOh;
        emit UpdateVeOh(msg.sender, address(oldVeOh), address(_newVeOh));
    }

    /// @notice updates factor after any veOh token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVeOhBalance the amount of veOh
    /// @dev can only be called by veOh
    function updateFactor(address _user, uint256 _newVeOhBalance) external override onlyVeOh {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount == 0) {
                continue;
            }

            PoolInfo storage pool = poolInfo[pid];

            // first, update pool
            _updatePool(pid);
            // calculate pending
            uint256 pending = ((user.amount * pool.accOhPerShare + user.factor * pool.accOhPerFactorShare) / 1e12) - user.rewardDebt;
            // increase claimableOh
            claimableOh[pid][_user] += pending;
            // get oldFactor
            uint256 oldFactor = user.factor; // get old factor
            // calculate newFactor using
            uint256 newFactor = Math.sqrt(_newVeOhBalance * user.amount);
            // update user factor
            user.factor = newFactor;
            // update reward debt, take into account newFactor
            user.rewardDebt = (user.amount * pool.accOhPerShare + newFactor * pool.accOhPerFactorShare) / 1e12;
            // also, update sumOfFactors
            pool.sumOfFactors = pool.sumOfFactors + newFactor - oldFactor;
        }
    }

    /// @notice In case we need to manually migrate OH funds from MasterChef
    /// Sends all remaining oh from the contract to the owner
    function emergencyOhWithdraw() external onlyOwner {
        oh.safeTransfer(address(msg.sender), oh.balanceOf(address(this)));
    }
}