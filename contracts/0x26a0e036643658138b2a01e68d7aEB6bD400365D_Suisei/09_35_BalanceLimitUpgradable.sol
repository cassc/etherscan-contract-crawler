//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";
import "./BalanceLimit.sol";

contract BalanceLimitUpgradable is Initializable, AdminManagerUpgradable {
    using BalanceLimit for BalanceLimit.Data;

    mapping(uint8 => BalanceLimit.Data) internal _balanceLimits;

    function __BalanceLimit_init() internal onlyInitializing {
        __AdminManager_init_unchained();
        __BalanceLimit_init_unchained();
    }

    function __BalanceLimit_init_unchained() internal onlyInitializing {}

    function _increaseBalance(
        uint8 stageId_,
        address account_,
        uint256 amount_
    ) internal {
        _balanceLimits[stageId_].increaseBalance(account_, amount_);
    }

    function currentBalance(uint8 stageId_, address account_)
        external
        view
        returns (uint256)
    {
        return _balanceLimits[stageId_].balances[account_];
    }

    function remainingBalance(uint8 stageId_, address account_)
        external
        view
        returns (uint256)
    {
        return
            _balanceLimits[stageId_].limit -
            _balanceLimits[stageId_].balances[account_];
    }

    function updateBalanceLimit(uint8 stageId_, uint256 limit_)
        public
        onlyAdmin
    {
        _balanceLimits[stageId_].limit = limit_;
    }

    function balanceLimit(uint8 stageId_) external view returns (uint256) {
        return _balanceLimits[stageId_].limit;
    }
}