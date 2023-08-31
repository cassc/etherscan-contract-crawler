//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../admin-manager/AdminManager.sol";
import "./BalanceLimitStorage.sol";

contract BalanceLimit is AdminManager {
    using BalanceLimitStorage for BalanceLimitStorage.Data;

    mapping(uint8 => BalanceLimitStorage.Data) internal _balanceLimits;

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