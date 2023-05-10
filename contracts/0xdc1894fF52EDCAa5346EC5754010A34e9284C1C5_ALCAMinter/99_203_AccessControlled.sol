// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract AccessControlled {
    error CallerNotLockup();
    error CallerNotLockupOrBonus();

    modifier onlyLockup() {
        if (msg.sender != _getLockupContractAddress()) {
            revert CallerNotLockup();
        }
        _;
    }

    modifier onlyLockupOrBonus() {
        // must protect increment of token balance
        if (
            msg.sender != _getLockupContractAddress() &&
            msg.sender != address(_getBonusPoolAddress())
        ) {
            revert CallerNotLockupOrBonus();
        }
        _;
    }

    function _getLockupContractAddress() internal view virtual returns (address);

    function _getBonusPoolAddress() internal view virtual returns (address);

    function _getRewardPoolAddress() internal view virtual returns (address);
}