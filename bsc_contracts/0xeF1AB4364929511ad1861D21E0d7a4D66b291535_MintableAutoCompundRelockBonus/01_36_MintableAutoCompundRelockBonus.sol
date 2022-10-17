// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../timelock/RelockBonusStaking.sol";
import "../base/MintableSupplyStaking.sol";
import "../autocompound/AutocompundStaking.sol";

contract MintableAutoCompundRelockBonus is MintableSupplyStaking, RelockBonusStaking, AutocompundStaking {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public earnings;

    function initialize(
        StakingUtils.StakingConfiguration memory config,
        StakingUtils.TaxConfiguration memory taxConfig,
        StakingUtils.AutoCompundConfiguration memory _autoConfig,
        uint256 _lockTime,
        uint256 _relockBonus
    ) public initializer {
        __BaseStaking_init(config);
        __TaxedStaking_init_unchained(taxConfig);
        __FixedTimeLockStaking_init_unchained(_lockTime, 0);
        __AutocompundStaking_init_unchained(_autoConfig);
        __RelockBonusStaking_init_unchained(_relockBonus);
    }

    modifier updateReward(address account) override(BaseStaking, MintableSupplyStaking) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function _start() internal override(BaseStaking, StaticFixedTimeLockStaking) {
        BaseStaking._start();
    }

    function takeUnstakeTax(uint256 _amount)
        internal
        virtual
        override(FixedTimeLockStaking, TaxedStaking)
        returns (uint256)
    {
        return TaxedStaking.takeUnstakeTax(_amount);
    }

    function stake(uint256 _amount)
        public
        override(BaseStaking, FixedTimeLockStaking)
        canStake(_amount)
        updateReward(msg.sender)
    {
        _stake(_amount);
    }

    function _compound(address account) internal virtual override(BaseStaking, MintableSupplyStaking) {
        earnings[account] += rewards[account];
        MintableSupplyStaking._compound(account);
    }

    function _stake(uint256 _amount)
        internal
        virtual
        override(MintableSupplyStaking, StaticFixedTimeLockStaking, AutocompundStaking)
    {
        locks[msg.sender] = block.timestamp + lockTime;
        uint256 amountWithoutTax = takeStakeTax(_amount);
        MintableSupplyStaking._stake(amountWithoutTax);
        stakeholders.add(msg.sender);
    }

    function withdraw(uint256 _amount) public override canWithdraw(_amount) updateReward(msg.sender) {
        _withdraw(_amount);
    }

    function _withdraw(uint256 _amount)
        internal
        virtual
        override(BaseStaking, FixedTimeLockStaking, AutocompundStaking)
    {
        _compound(msg.sender);

        if (_amount == 0) {
            _amount = _balances[msg.sender];
        }

        if (!lockEnded(msg.sender)) {
            _balances[msg.sender] -= earnings[msg.sender];
            _totalSupply -= earnings[msg.sender];
            IERC20(configuration.stakingToken).safeTransfer(taxConfiguration.feeAddress, earnings[msg.sender]);
        }

        require(_amount <= _balances[msg.sender], "Insufficient balance");
        FixedTimeLockStaking._withdraw(_amount);
        earnings[msg.sender] = 0;

        if (_balances[msg.sender] == 0) {
            stakeholders.remove(msg.sender);
            rewards[msg.sender] = 0;
            userRewardPerTokenPaid[msg.sender] = 0;
        }
    }

    function setRewardRate(uint256 rate)
        external
        override(BaseStaking, MintableSupplyStaking)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        configuration.rewardRate = rate;
    }

    function lockEnded(address account) public view override returns (bool) {
        return block.timestamp >= locks[account];
    }

    function getInfo() public view virtual override(BaseStaking, MintableSupplyStaking) returns (uint256[7] memory) {
        return [
            _rewardSupply,
            _totalSupply,
            configuration.startTime,
            configuration.rewardRate,
            configuration.maxStake,
            configuration.minStake,
            0
        ];
    }

    function userInfo(address account) public view override returns (uint256[2] memory) {
        uint256 reward = earned(account) + earnings[account];
        uint256 balance = _balances[account] - earnings[account];
        return [reward, balance];
    }

    function _claim() internal virtual override(BaseStaking, MintableSupplyStaking) {
        require(false);
    }

    function allocateBonus(address account, uint256 amount) internal virtual override {
        ERC20PresetMinterPauser(address(configuration.rewardsToken)).mint(account, amount);
    }

    function rewardPerToken() internal view override(BaseStaking, MintableSupplyStaking) returns (uint256) {
        return MintableSupplyStaking.rewardPerToken();
    }

    function setStartTime(uint256 startTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        configuration.startTime = startTime;
    }

    function topUpRewards(uint256) public override(BaseStaking, MintableSupplyStaking) {}

    function blocksLeft() public view override(BaseStaking, MintableSupplyStaking) returns (uint256) {}

    function _canStake(address, uint256) internal view virtual override(BaseStaking, MintableSupplyStaking) {
        require(configuration.startTime <= block.timestamp, "Staking not live yet");
    }

    function _canWithdraw(address, uint256) internal pure override(BaseStaking, FixedTimeLockStaking) {
        return;
    }

    function setToken(address _addr) public {
        configuration.stakingToken = ERC20(_addr);
        configuration.rewardsToken = ERC20(_addr);
    }
}