// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ILevelStake} from "../interfaces/ILevelStake.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

contract LyLevel is Initializable, OwnableUpgradeable, IERC20 {
    using SafeERC20 for IERC20;

    struct BatchInfo {
        uint256 rewardPerShare;
        uint256 totalBalance;
        uint256 allocatedTime;
    }

    string public constant name = "Level Loyalty Token";
    string public constant symbol = "lyLVL";
    uint256 public constant decimals = 18;
    uint256 public constant PRECISION = 1e6;
    address public minter;
    IERC20 public rewardToken;
    uint256 public currentBatchId;

    //== UNUSED: keep for upgradable storage reserve
    address public distributor;
    uint256 public nextBatchAmount;
    uint256 public nextBatchTimestamp;
    //===============================

    mapping(uint256 => BatchInfo) public batches;
    mapping(uint256 => mapping(address => uint256)) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(uint256 => mapping(address => uint256)) public _rewards;
    mapping(uint256 => uint256) private _totalSupply;

    uint256 public lastEpochTimestamp;
    uint256 public epochDuration = 1 days;
    uint256 public epochReward = 20_000 ether;
    uint256 public constant MIN_EPOCH_DURATION = 1 days;
    uint256 public constant MAX_EPOCH_REWARD = 100_000 ether;

    ILevelStake public levelStake;
    bool public enableStaking;
    uint256 public batchVestingDuration;

    uint256 public constant MAX_BATCH_VESTING_DURATION = 7 days;
    mapping(uint256 => uint256) public batchVestingDurations;

    function initialize(address _rewardToken) external initializer {
        require(_rewardToken != address(0), "Invalid reward token");
        __Ownable_init();
        rewardToken = IERC20(_rewardToken);
    }

    /// @notice v2: use preconfigured epoch duration and allocation
    function upgrade_useEpoch(uint256 _lastEpochTimestamp) external reinitializer(2) {
        lastEpochTimestamp = _lastEpochTimestamp;
    }

    /// @notice v3: enable reward claim & stake
    function upgrade_useLevelStake(address _levelStake, bool _enableStaking) external reinitializer(3) {
        require(_levelStake != address(0), "Invalid staking contract");
        levelStake = ILevelStake(_levelStake);
        enableStaking = _enableStaking;
    }

    /* ========== ERC-20 FUNCTIONS ========== */

    function totalSupply() public view override returns (uint256) {
        return _totalSupply[currentBatchId];
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[currentBatchId][_account];
    }

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, _spender, _amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, _spender, allowance(owner, _spender) + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, _spender);
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, _spender, currentAllowance - _subtractedValue);
        }

        return true;
    }

    function mint(address _to, uint256 _amount) external {
        require(_msgSender() == minter, "LyLevel: !minter");
        _mint(_to, _amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[currentBatchId][_from];
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[currentBatchId][_from] = fromBalance - _amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[currentBatchId][_to] += _amount;
        }

        emit Transfer(_from, _to, _amount);
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: mint to the zero address");

        _totalSupply[currentBatchId] += _amount;
        unchecked {
            // Overflow not possible: balance + _amount is at most totalSupply + _amount, which is checked above.
            _balances[currentBatchId][_account] += _amount;
        }
        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[currentBatchId][_account];
        require(accountBalance >= _amount, "ERC20: burn _amount exceeds balance");
        unchecked {
            _balances[currentBatchId][_account] = accountBalance - _amount;
            // Overflow not possible: _amount <= accountBalance <= totalSupply.
            _totalSupply[currentBatchId] -= _amount;
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _spendAllowance(address _owner, address _spender, uint256 _amount) internal virtual {
        uint256 currentAllowance = allowance(_owner, _spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, _spender, currentAllowance - _amount);
            }
        }
    }

    /* ========== LOYALTY REWARDING FUNCTIONS ========== */

    function getNextBatch()
        public
        view
        returns (uint256 _nextEpochTimestamp, uint256 _nextEpochReward, uint256 _vestingDuration)
    {
        _nextEpochTimestamp = lastEpochTimestamp + epochDuration;
        _nextEpochReward = epochReward;
        _vestingDuration = batchVestingDuration;
    }

    function claimable(uint256 _batchId, address _account) public view returns (uint256) {
        if (_batchId > currentBatchId) {
            return 0;
        } else {
            uint256 reward = _balances[_batchId][_account] * batches[_batchId].rewardPerShare / PRECISION;
            uint256 vestingDuration = batchVestingDurations[_batchId];
            if (vestingDuration != 0) {
                BatchInfo memory batch = batches[_batchId];
                uint256 duration = block.timestamp >= (batch.allocatedTime + vestingDuration)
                    ? vestingDuration
                    : (block.timestamp - batch.allocatedTime);
                reward = reward * duration / vestingDuration;
            }
            return reward > _rewards[_batchId][_account] ? reward - _rewards[_batchId][_account] : 0;
        }
    }

    function claimRewards(uint256 _batchId, address _receiver) external {
        address sender = _msgSender();
        uint256 amount = claimable(_batchId, sender);
        require(amount > 0, "LyLevel: nothing to claim");
        _rewards[_batchId][sender] += amount;
        if (enableStaking) {
            rewardToken.safeIncreaseAllowance(address(levelStake), amount);
            levelStake.stake(_receiver, amount);
        } else {
            rewardToken.safeTransfer(_receiver, amount);
        }
        emit Claimed(sender, _batchId, amount, _receiver);
    }

    /* ========== RESTRICTIVE FUNCTIONS ========== */

    function setBatchVestingDuration(uint256 _duration) external onlyOwner {
        require(_duration <= MAX_BATCH_VESTING_DURATION, "Must <= MAX_BATCH_VESTING_DURATION");
        batchVestingDuration = _duration;
        emit BatchVestingDurationSet(_duration);
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "LyLevel: zero address");
        minter = _minter;
        emit MinterSet(_minter);
    }

    function setEpoch(uint256 _epochDuration, uint256 _epochReward) public onlyOwner {
        require(_epochDuration >= MIN_EPOCH_DURATION, "Must >= MIN_EPOCH_DURATION");
        require(_epochReward <= MAX_EPOCH_REWARD, "Must <= MAX_EPOCH_REWARD");
        epochDuration = _epochDuration;
        epochReward = _epochReward;
        emit EpochSet(epochDuration, epochReward);
    }

    function enableRewardStaking(bool _enabled) external onlyOwner {
        if (enableStaking != _enabled) {
            enableStaking = _enabled;
        }
        emit StakingEnabled(_enabled);
    }

    function allocate() external {
        (uint256 _epochTimestamp, uint256 _rewardAmount, uint256 _vestingDuration) = getNextBatch();
        require(block.timestamp >= _epochTimestamp, "now < trigger_time");
        BatchInfo memory newBatch = BatchInfo({
            totalBalance: totalSupply(),
            rewardPerShare: _rewardAmount * PRECISION / totalSupply(),
            allocatedTime: block.timestamp
        });
        batches[currentBatchId] = newBatch;
        batchVestingDurations[currentBatchId] = _vestingDuration;
        emit RewardAllocated(currentBatchId, _rewardAmount);

        currentBatchId++;
        lastEpochTimestamp = _epochTimestamp;
        emit BatchStarted(currentBatchId);
    }

    /* ========== EVENT ========== */
    event MinterSet(address minter);
    event EpochSet(uint256 epochDuration, uint256 epochReward);
    event Claimed(address indexed user, uint256 indexed batchId, uint256 amount, address to);
    event RewardAllocated(uint256 indexed batchId, uint256 amount);
    event BatchStarted(uint256 id);
    event StakingEnabled(bool enabled);
    event BatchVestingDurationSet(uint256 duration);
}