// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../BaseRewardPool.sol";

contract BaseRewardPoolLocked is BaseRewardPool {
    uint256 public unlockAt;
    address public lockManager;

    mapping(address => uint256) public lockedBalance;

    event LockSet(address indexed _account, uint256 _amount);

    function setUnlockAt(uint256 _unlockAt) external onlyOwner {
        require(unlockAt == 0, "already set");
        unlockAt = _unlockAt;
    }

    function setLockManager(address _lockManager) external onlyOwner {
        lockManager = _lockManager;
    }

    function setLock(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external {
        require(msg.sender == lockManager, "!auth");
        uint256 len = _accounts.length;
        require(len == _amounts.length, "!len");

        for (uint256 i = 0; i < len; i++) {
            lockedBalance[_accounts[i]] = _amounts[i];
            emit LockSet(_accounts[i], _amounts[i]);
        }
    }

    function _withdraw(address _account, uint256 _amount) internal override {
        super._withdraw(_account, _amount);
        _checkLockedBalance(_account);
    }

    function _checkLockedBalance(address _account) internal view {
        require(
            block.timestamp > unlockAt ||
                balanceOf(_account) >= lockedBalance[_account],
            "locked"
        );
    }
}