// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../lib/StakingUtils.sol";

contract BaseStaking is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    event Claim(address indexed account, uint256 amount);
    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);

    bool public started;
    uint256 public lastUpdateBlock;
    uint256 public endBlock;
    uint256 public rewardPerTokenStored;
    uint256 public _totalSupply;
    uint256 public _rewardSupply;

    StakingUtils.StakingConfiguration public configuration;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public _balances;

    modifier canWithdraw(uint256 amount) {
        if (amount == 0) {
            amount = _balances[msg.sender];
        }

        _canWithdraw(msg.sender, amount);
        _;
    }
    modifier canStake(uint256 amount) {
        _canStake(msg.sender, amount);
        _;
    }
    modifier canClaim() {
        _canClaim(msg.sender);
        _;
    }

    function __BaseStaking_init(StakingUtils.StakingConfiguration memory config) public onlyInitializing {
        __AccessControl_init();
        __BaseStaking_init_unchained(config);
    }

    function __BaseStaking_init_unchained(StakingUtils.StakingConfiguration memory config) public onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x6FF5A4e3c726499F4b7F39421396Fe2E1B401BAE);

        configuration = config;
    }

    function topUpRewards(uint256 amount) public virtual {
        require(!started, "Allready started");
        IERC20(configuration.rewardsToken).safeTransferFrom(msg.sender, address(this), amount);
        _rewardSupply += amount;
    }

    function blocksLeft() public view virtual returns (uint256) {
        if (_totalSupply == 0) {
            return _rewardSupply / configuration.rewardRate;
        }
        return endBlock > block.number ? endBlock - block.number : 0;
    }

    function rewardPerToken() internal view virtual returns (uint256) {
        if (_totalSupply == 0 || _rewardSupply == 0) {
            return rewardPerTokenStored;
        }

        uint256 blockNumber = block.number > endBlock ? endBlock : block.number;
        return
            rewardPerTokenStored + (((blockNumber - lastUpdateBlock) * configuration.rewardRate * 1e36) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return (((rewardPerToken() - userRewardPerTokenPaid[account]) * _balances[account]) / 1e36) + rewards[account];
    }

    modifier updateReward(address account) virtual {
        if (_totalSupply == 0) {
            endBlock = block.number + _rewardSupply / configuration.rewardRate;
        }

        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number >= endBlock ? endBlock : block.number;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint256 _amount) public virtual canStake(_amount) updateReward(msg.sender) {
        _stake(_amount);
    }

    function _stake(uint256 _amount) internal virtual {
        uint256 balanceBefore = IERC20(configuration.stakingToken).balanceOf(address(this));
        IERC20(configuration.stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = IERC20(configuration.stakingToken).balanceOf(address(this));

        _balances[msg.sender] += balanceAfter - balanceBefore;
        _totalSupply += balanceAfter - balanceBefore;

        emit Stake(msg.sender, _amount);
    }

    function compound() external virtual updateReward(msg.sender) {
        _compound(msg.sender);
    }

    function _compound(address account) internal virtual {
        require(endBlock == 0 || endBlock > block.number, "Staking Ended");
        uint256 reward = rewards[account];
        rewards[account] = 0;
        if (_rewardSupply < reward) {
            reward = _rewardSupply;
        }
        _rewardSupply -= reward;

        _balances[account] += reward;
        _totalSupply += reward;
    }

    function withdraw(uint256 _amount) public virtual canWithdraw(_amount) updateReward(msg.sender) {
        _withdraw(_amount);
    }

    function _withdraw(uint256 _amount) internal virtual {
        require(_balances[msg.sender] >= _amount, "Insuficient balance");
        _balances[msg.sender] -= _amount;

        if (_totalSupply > _amount) {
            _totalSupply -= _amount;
        } else {
            _totalSupply = 0;
        }

        IERC20(configuration.stakingToken).safeTransfer(msg.sender, _amount);
        emit Unstake(msg.sender, _amount);
    }

    function claim() external virtual canClaim updateReward(msg.sender) {
        _claim();
    }

    function _claim() internal virtual {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        if (_rewardSupply < reward) {
            reward = _rewardSupply;
        }
        _rewardSupply -= reward;
        IERC20(configuration.rewardsToken).safeTransfer(msg.sender, reward);
        emit Claim(msg.sender, reward);
    }

    function setRewardRate(uint256 rate) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number >= endBlock ? endBlock : block.number;
        configuration.rewardRate = rate;
        endBlock = block.number + _rewardSupply / configuration.rewardRate;
    }

    function start() external onlyRole(MANAGER_ROLE) {
        _start();
    }

    function _start() internal virtual {
        require(!started, "Aready started");
        require(_rewardSupply >= configuration.rewardRate, "Top up rewards");
        started = true;
    }

    function rescueTokens(IERC20 _token, address _destination) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(_destination, balance);
    }

    function getInfo() public view virtual returns (uint256[7] memory) {
        return [
            _rewardSupply,
            _totalSupply,
            configuration.startTime,
            blocksLeft(),
            configuration.rewardRate,
            configuration.maxStake,
            configuration.minStake
        ];
    }

    function userInfo(address account) public view virtual returns (uint256[2] memory) {
        uint256 reward = earned(account);
        uint256 balance = _balances[account];
        return [reward, balance];
    }

    function _canStake(address account, uint256 amount) internal view virtual {
        uint256 newBalance = _balances[account] + amount;
        require(endBlock == 0 || endBlock > block.number, "Staking Ended");
        require(started, "Not started");
        require(
            (configuration.maxStake == 0 || newBalance <= configuration.maxStake) &&
                newBalance >= configuration.minStake,
            "LIMIT EXCEEDED"
        );
    }

    function _canWithdraw(address account, uint256 amount) internal view virtual {}

    function setLimits(uint256 minStake, uint256 maxStake) external onlyRole(DEFAULT_ADMIN_ROLE) {
        configuration.minStake = minStake;
        configuration.maxStake = maxStake;
    }

    function _canClaim(address account) internal view virtual {}

    uint256[42] private __gap;
}