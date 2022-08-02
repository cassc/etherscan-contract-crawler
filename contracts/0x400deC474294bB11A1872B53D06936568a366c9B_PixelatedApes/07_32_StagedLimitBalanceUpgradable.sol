//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AdminManagerUpgradable.sol";
import "./LimitBalances.sol";

contract StagedLimitBalanceUpgradable is Initializable, AdminManagerUpgradable {
    using LimitBalances for LimitBalances.Data;

    mapping(uint8 => LimitBalances.Data) internal _limitBalanceConfigs;

    function __StagedLimitBalance_init() internal onlyInitializing {
        __AdminManager_init_unchained();
        __StagedLimitBalance_init_unchained();
    }

    function __StagedLimitBalance_init_unchained() internal onlyInitializing {}

    function updateLimit(uint8 stageId_, uint256 limit_) public onlyAdmin {
        _limitBalanceConfigs[stageId_].limit = limit_;
    }

    function increaseBalance(
        uint8 stageId_,
        address account_,
        uint256 amount_
    ) internal {
        _limitBalanceConfigs[stageId_].increaseBalance(account_, amount_);
    }
}