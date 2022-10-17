// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../base/TaxedStaking.sol";

contract FixedTimeLockStaking is TaxedStaking {
    using SafeERC20 for IERC20;

    bool public allowEarlyUnlock;
    uint256 public lockTime;
    uint256 public earlyUnlockPenalty;
    mapping(address => uint256) public locks;

    function __FixedTimeLockStaking_init(
        StakingUtils.StakingConfiguration memory config,
        StakingUtils.TaxConfiguration memory taxConfig,
        uint256 _lockTime,
        uint256 penalty
    ) public onlyInitializing {
        __TaxedStaking_init(config, taxConfig);
        __FixedTimeLockStaking_init_unchained(_lockTime, penalty);
    }

    function __FixedTimeLockStaking_init_unchained(uint256 _lockTime, uint256 penalty) public onlyInitializing {
        lockTime = _lockTime * 1 days;
        earlyUnlockPenalty = penalty;
    }

    function stake(uint256 _amount) public virtual override canStake(_amount) updateReward(msg.sender) {
        super._stake(_amount);
        _stake(_amount);
    }

    function _withdraw(uint256 _amount) internal virtual override {
        TaxedStaking._withdraw(_amount);
        if (_balances[msg.sender] == 0) {
            locks[msg.sender] = 0;
        }
    }

    function _stake(uint256) internal virtual override {
        locks[msg.sender] = block.timestamp + lockTime;
    }

    function _canWithdraw(address account, uint256 amount) internal view virtual override {
        super._canWithdraw(account, amount);

        if (!allowEarlyUnlock) {
            require(lockEnded(msg.sender), "LOCK ACTIVE");
        }
    }

    function timelockConfigurations() public view returns (uint256[2] memory) {
        return [lockTime, earlyUnlockPenalty];
    }

    function takeUnstakeTax(uint256 _amount) internal virtual override returns (uint256) {
        if (earlyUnlockPenalty > 0 && !lockEnded(msg.sender)) {
            uint256 tax = (_amount * earlyUnlockPenalty) / 10_000;
            _amount -= tax;
            _balances[msg.sender] -= tax;
            _totalSupply -= tax;
            IERC20(configuration.stakingToken).safeTransfer(taxConfiguration.feeAddress, tax);
        }
        return TaxedStaking.takeUnstakeTax(_amount);
    }

    function lockEnded(address account) public view virtual returns (bool) {
        return blocksLeft() == 0 || block.timestamp >= locks[account] || _rewardSupply == 0;
    }

    function setTimelock(uint256 _lockTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockTime = _lockTime * 1 days;
    }

    function setPenalty(uint256 penalty) external onlyRole(DEFAULT_ADMIN_ROLE) {
        earlyUnlockPenalty = penalty;
    }

    function setAllowEarlyUnlock(bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowEarlyUnlock = status;
    }

    uint256[46] private __gap;
}