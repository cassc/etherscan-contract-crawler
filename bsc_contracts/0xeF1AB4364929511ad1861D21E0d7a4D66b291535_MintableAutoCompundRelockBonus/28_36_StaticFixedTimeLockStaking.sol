// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../base/TaxedStaking.sol";
import "./FixedTimeLockStaking.sol";

contract StaticFixedTimeLockStaking is FixedTimeLockStaking {

    uint256 public unlockTime;

    function __StaticFixedTimeLockStaking_init(
        StakingUtils.StakingConfiguration memory config,
        StakingUtils.TaxConfiguration memory taxConfig,
        uint256 _lockTime,
        uint256 penalty
    ) public onlyInitializing {
        __TaxedStaking_init(config, taxConfig);
        __FixedTimeLockStaking_init_unchained(_lockTime, penalty);
    }

    function _start() internal virtual override(BaseStaking) {
        BaseStaking._start();
        unlockTime = block.timestamp + lockTime;
    }

    function _stake(uint256) internal virtual override {
        locks[msg.sender] = unlockTime;   
    }

    function updateLock(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        locks[account] = block.timestamp + lockTime;
    }

    uint256[50] private __gap;
}