// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '../../../openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../../../openzeppelin-upgradeable/security/PausableUpgradeable.sol';
import '../../../openzeppelin-upgradeable/proxy/utils/Initializable.sol';
import '../../../openzeppelin/token/ERC20/utils/SafeERC20.sol';
import '../../../openzeppelin/token/ERC20/ERC20.sol';
import '../../../openzeppelin/utils/structs/EnumerableSet.sol';
import '../../../openzeppelin/utils/Address.sol';
import '../libraries/Math.sol';
import '../../../openzeppelin-upgradeable/access/OwnableUpgradeable.sol';
import '../interfaces/IVeToken.sol';
import '../interfaces/IRewarder.sol';
import '../interfaces/IPermit.sol';

/// MasterChef is a boss. He says "go f your blocks maki boy, I'm gonna use timestamp instead"
/// In addition, he feeds himself from Venom. So, veToken holders boost their (non-dialuting) emissions.
/// This contract rewards users in function of their amount of lp staked (dialuting pool) factor (non-dialuting pool)
/// Factor and sumOfFactors are updated by contract VeToken.sol after any veToken minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Token is sufficiently
/// distributed and the community can show to govern itself.
contract MasterChefEth is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 factor; // non-dialuting factor = sqrt (lpAmount * veToken.balanceOf())
        //
        // We do some fancy math here. Basically, any point in time, the amount of Tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accTokenPerShare + user.factor * pool.accTokenPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare`, `accTokenPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 amount; // Amount of LP token contract.
        uint256 allocPoint; // How many base allocation points assigned to this pool
        uint256 lastRewardTimestamp; // Last timestamp that Tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated Tokens per share, times 1e12.
        IRewarder rewarder;
        uint256 sumOfFactors; // the sum of all non dialuting factors by all of the users in the pool
        uint256 accTokenPerFactorShare; // accumulated tokenw per factor share
    }

    // The strongest ptp out there (token).
    IERC20 public token;
    // Venom does not seem to hurt the Token, it only makes it stronger.
    IVeToken public veToken;
    // the orderMgr address.
    address public orderMgr;
    // tokens created per second.
    uint256 public tokenPerSec;
    // Emissions: both must add to 1000 => 100%
    // Dialuting emissions repartition (e.g. 300 for 30%)
    uint256 public dialutingRepartition;
    // Non-dialuting emissions repartition (e.g. 500 for 50%)
    uint256 public nonDialutingRepartition;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when Token mining starts.
    uint256 public startTimestamp;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet private lpTokens;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Amount of claimable token the user has
    mapping(uint256 => mapping(address => uint256)) public claimableToken;
    address public esHashAutoDeposit;

    event Add(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event Set(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event Deposit(address indexed caller, address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed caller, address indexed user, uint256 indexed pid, uint256 amount);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accTokenPerShare);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 tokenPerSec);
    event UpdateEmissionRepartition(
        address indexed user,
        uint256 dialutingRepartition,
        uint256 nonDialutingRepartition
    );
    event UpdateVeToken(address indexed user, address oldVeToken, address newVeToken);
    event UpdateOrderMgr(address indexed user, address oldOrderMgr, address newOderMgr);

    /// @dev Modifier ensuring that certain function can only be called by VeToken
    modifier onlyVeToken() {
        require(address(veToken) == msg.sender, 'notVeToken: wut?');
        _;
    }
    modifier onlyOrderMgrEsHash() {
        require(orderMgr == msg.sender || esHashAutoDeposit == msg.sender, 'notFund: wut?');
        _;
    }

    function initialize(
        IERC20 _token,
        IVeToken _veToken,
        uint256 _tokenPerSec,
        uint256 _dialutingRepartition,
        uint256 _startTimestamp
    ) public initializer {
        require(address(_token) != address(0), 'token address cannot be zero');
        require(address(_veToken) != address(0), 'veToken address cannot be zero');
        require(_tokenPerSec != 0, 'token per sec cannot be zero');
        require(_dialutingRepartition <= 1000, 'dialuting repartition must be in range 0, 1000');

        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        token = _token;
        veToken = _veToken;
        tokenPerSec = _tokenPerSec;
        dialutingRepartition = _dialutingRepartition;
        nonDialutingRepartition = 1000 - _dialutingRepartition;
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

    /// @notice returns pool length
    function poolLength() external view returns (uint256) {
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
        // update all pools
        massUpdatePools();

        // update last time rewards were calculated to now
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;

        // update alloc point
        totalAllocPoint += _allocPoint;

        // update PoolInfo with the new LP
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                amount: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accTokenPerShare: 0,
                rewarder: _rewarder,
                sumOfFactors: 0,
                accTokenPerFactorShare: 0
            })
        );

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(poolInfo.length - 1, _allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's Token allocation point. Can only be called by the owner.
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
        massUpdatePools();

        PoolInfo storage pool = poolInfo[_pid];

        totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.allocPoint = _allocPoint;

        if (overwrite) {
            pool.rewarder = _rewarder;
        }
        emit Set(_pid, _allocPoint, overwrite ? _rewarder : pool.rewarder, overwrite);
    }

    /// @notice View function to see pending Tokens on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    /// TODO include factor operations
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingToken,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 accTokenPerFactorShare = pool.accTokenPerFactorShare;
        uint256 lpSupply = pool.amount;
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;
            uint256 tokenReward = (secondsElapsed * tokenPerSec * pool.allocPoint) / totalAllocPoint;
            accTokenPerShare += (tokenReward * 1e12 * dialutingRepartition) / (lpSupply * 1000);
            if (pool.sumOfFactors != 0) {
                accTokenPerFactorShare += (tokenReward * 1e12 * nonDialutingRepartition) / (pool.sumOfFactors * 1000);
            }
        }
        pendingToken =
            ((user.amount * accTokenPerShare + user.factor * accTokenPerFactorShare) / 1e12) +
            claimableToken[_pid][_user] -
            user.rewardDebt;
        // If it's a double reward farm, we return info about the bonus token
        if (address(pool.rewarder) != address(0)) {
            (bonusTokenAddress, bonusTokenSymbol) = rewarderBonusTokenInfo(_pid);
            pendingBonusToken = pool.rewarder.pendingTokens(_user);
        }
    }

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(uint256 _pid)
        public
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol)
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) != address(0)) {
            bonusTokenAddress = address(pool.rewarder.rewardToken());
            bonusTokenSymbol = IERC20Metadata(pool.rewarder.rewardToken()).symbol();
        }
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        // update only if now > last time we updated rewards
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lpSupply = pool.amount;

            // if balance of lp supply is 0, update lastRewardTime and quit function
            if (lpSupply == 0) {
                pool.lastRewardTimestamp = block.timestamp;
                return;
            }
            // calculate seconds elapsed since last update
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;

            // calculate token reward
            uint256 tokenReward = (secondsElapsed * tokenPerSec * pool.allocPoint) / totalAllocPoint;
            // update accTokenPerShare to reflect dialuting rewards
            pool.accTokenPerShare += (tokenReward * 1e12 * dialutingRepartition) / (lpSupply * 1000);

            // update accTokenPerFactorShare to reflect non-dialuting rewards
            if (pool.sumOfFactors == 0) {
                pool.accTokenPerFactorShare = 0;
            } else {
                pool.accTokenPerFactorShare += (tokenReward * 1e12 * nonDialutingRepartition) / (pool.sumOfFactors * 1000);
            }

            // update lastRewardTimestamp to now
            pool.lastRewardTimestamp = block.timestamp;
            emit UpdatePool(_pid, pool.lastRewardTimestamp, lpSupply, pool.accTokenPerShare);
        }
    }
    function _harvest(
		PoolInfo storage pool,
		UserInfo storage user,
		uint256 _pid,
		address _user,
        bool _needHarvest
	) internal {
        if (user.amount > 0) {
			// Harvest Token
			uint256 pending = ((user.amount * pool.accTokenPerShare + user.factor * pool.accTokenPerFactorShare) / 1e12) +
				claimableToken[_pid][_user] -
				user.rewardDebt;
            if (_needHarvest) {
			    claimableToken[_pid][_user] = 0;
			    pending = safeTokenTransfer(payable(_user), pending);
			    emit Harvest(_user, _pid, pending);
            } else {
			    claimableToken[_pid][_user] = pending;
            }
		} else if (_needHarvest) {
            uint256 pending = claimableToken[_pid][_user];
            claimableToken[_pid][_user] = 0;
            safeTokenTransfer(payable(_user), pending);
            emit Harvest(_user, _pid, pending);
		}
	}

    function _deposit(
        uint256 _pid,
        uint256 _amount,
        address _user,
		bool _needHarvest
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        _updatePool(_pid);
    	_harvest(pool, user, _pid, _user, _needHarvest);

        // update amount of lp staked by user
        user.amount += _amount;
        pool.amount += _amount;

        // update non-dialuting factor
        uint256 oldFactor = user.factor;
        user.factor = Math.sqrt(user.amount * veToken.balanceOf(_user));
        pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accTokenPerShare + user.factor * pool.accTokenPerFactorShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(_user, user.amount);
        }

        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for Token allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(uint256 _pid, uint256 _amount)
        external
        nonReentrant
    {
		_deposit(_pid, _amount, msg.sender, true);
    }

    function depositWithPermit(uint256 _pid, uint256 _amount,
        uint256 deadline, uint256 value, uint8 v, bytes32 r, bytes32 s)
        external
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        IPermit(address(pool.lpToken)).permit(msg.sender, address(this), value, deadline, v, r, s);
        _deposit(_pid, _amount, msg.sender, true);
    }

    /// @notice Withdraw LP tokens from MasterChef.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function _withdraw(uint256 _pid, uint256 _amount, address _user, bool _needHarvest)
		internal
	{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, 'withdraw: not good');

        _updatePool(_pid);
    	_harvest(pool, user, _pid, _user, _needHarvest);

        // for non-dialuting factor
        uint256 oldFactor = user.factor;

        // update amount of lp staked
        user.amount = user.amount - _amount;
        pool.amount -= _amount;

        // update non-dialuting factor
        user.factor = Math.sqrt(user.amount * veToken.balanceOf(_user));
        pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accTokenPerShare + user.factor * pool.accTokenPerFactorShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        uint256 additionalRewards;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onReward(_user, user.amount);
        }

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _user, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount)
        external
        nonReentrant
    {
    	_withdraw(_pid, _amount, msg.sender, true);
	}

    /// @notice Safe token transfer function, just in case if rounding error causes pool to not have enough Tokens.
    /// @param _to beneficiary
    /// @param _amount the amount to transfer
    function safeTokenTransfer(address payable _to, uint256 _amount) internal returns (uint256) {
        uint256 tokenBal = token.balanceOf(address(this));

        // perform additional check in case there are no more token tokens to distribute.
        // emergency withdraw would be necessary
        require(tokenBal > 0, 'No tokens to distribute');

        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
            return tokenBal;
        } else {
            token.transfer(_to, _amount);
            return _amount;
        }
    }

    /// @notice updates emission rate
    /// @param _tokenPerSec token amount to be updated
    /// @dev Pancake has to add hidden dummy pools inorder to alter the emission,
    /// @dev here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _tokenPerSec) external onlyOwner {
        massUpdatePools();
        tokenPerSec = _tokenPerSec;
        emit UpdateEmissionRate(msg.sender, _tokenPerSec);
    }

    /// @notice updates emission repartition
    /// @param _dialutingRepartition the future dialuting repartition
    function updateEmissionRepartition(uint256 _dialutingRepartition) external onlyOwner {
        require(_dialutingRepartition <= 1000);
        massUpdatePools();
        dialutingRepartition = _dialutingRepartition;
        nonDialutingRepartition = 1000 - _dialutingRepartition;
        emit UpdateEmissionRepartition(msg.sender, _dialutingRepartition, 1000 - _dialutingRepartition);
    }

    /// @notice updates veToken address
    /// @param _newVeToken the new VeToken address
    function setVeToken(IVeToken _newVeToken) external onlyOwner {
        require(address(_newVeToken) != address(0));
        massUpdatePools();
        emit UpdateVeToken(msg.sender, address(veToken), address(_newVeToken));
        veToken = _newVeToken;
    }

    /// @notice updates factor after any veToken token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVeTokenBalance the amount of veToken
    /// @dev can only be called by veToken
    function updateFactor(address _user, uint256 _newVeTokenBalance) external onlyVeToken {
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
            uint256 pending = ((user.amount * pool.accTokenPerShare + user.factor * pool.accTokenPerFactorShare) / 1e12) -
                user.rewardDebt;
            // increase claimableToken
            claimableToken[pid][_user] += pending;
            // get oldFactor
            uint256 oldFactor = user.factor; // get old factor
            // calculate newFactor using
            uint256 newFactor = Math.sqrt(_newVeTokenBalance * user.amount);
            // update user factor
            user.factor = newFactor;
            // update reward debt, take into account newFactor
            user.rewardDebt = (user.amount * pool.accTokenPerShare + newFactor * pool.accTokenPerFactorShare) / 1e12;
            // also, update sumOfFactors
            pool.sumOfFactors = pool.sumOfFactors + newFactor - oldFactor;
        }
    }
}