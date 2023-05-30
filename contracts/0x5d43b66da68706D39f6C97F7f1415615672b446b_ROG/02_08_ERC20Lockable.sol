// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";
import "../library/Ownable.sol";

abstract contract ERC20Lockable is ERC20, Ownable {
    struct LockInfo {
        uint256 amount;
        uint256 due;
    }

    mapping(address => LockInfo[]) internal _locks;
    mapping(address => uint256) internal _totalLocked;

    event Lock(address indexed from, uint256 amount, uint256 due);
    event Unlock(address indexed from, uint256 amount);

    modifier checkLock(address from, uint256 amount) {
        require(
            _balances[from] >= _totalLocked[from] + amount,
            "ERC20Lockable/Cannot send more than unlocked amount"
        );
        _;
    }

    function _lock(
        address from,
        uint256 amount,
        uint256 due
    ) internal returns (bool success) {
        require(
            due > block.timestamp,
            "ERC20Lockable/lock : Cannot set due to past"
        );
        require(
            _balances[from] >= amount + _totalLocked[from],
            "ERC20Lockable/lock : locked total should be smaller than balance"
        );
        _totalLocked[from] = _totalLocked[from] + amount;
        _locks[from].push(LockInfo(amount, due));
        emit Lock(from, amount, due);
        success = true;
    }

    function _unlock(address from, uint256 index)
        internal
        returns (bool success)
    {
        LockInfo storage lock = _locks[from][index];
        _totalLocked[from] = _totalLocked[from] - lock.amount;
        emit Unlock(from, lock.amount);
        _locks[from][index] = _locks[from][_locks[from].length - 1];
        _locks[from].pop();
        success = true;
    }

    function unlock(address from, uint256 idx) external returns (bool success) {
        require(
            _locks[from][idx].due < block.timestamp,
            "ERC20Lockable/unlock: cannot unlock before due"
        );
        _unlock(from, idx);
    }

    function unlockAll(address from) external returns (bool success) {
        for (uint256 i = 0; i < _locks[from].length; ) {
            i++;
            if (_locks[from][i - 1].due < block.timestamp) {
                if (_unlock(from, i - 1)) {
                    i--;
                }
            }
        }
        success = true;
    }

    function releaseLock(address from)
        external
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < _locks[from].length; ) {
            i++;
            if (_unlock(from, i - 1)) {
                i--;
            }
        }
        success = true;
    }

    function transferWithLockUp(
        address recipient,
        uint256 amount,
        uint256 due
    ) external onlyOwner returns (bool success) {
        require(
            recipient != address(0),
            "ERC20Lockable/transferWithLockUp : Cannot send to zero address"
        );
        _transfer(msg.sender, recipient, amount);
        _lock(recipient, amount, due);
        success = true;
    }

    function lockInfo(address locked, uint256 index)
        external
        view
        returns (uint256 amount, uint256 due)
    {
        LockInfo memory lock = _locks[locked][index];
        amount = lock.amount;
        due = lock.due;
    }

    function totalLocked(address locked)
        external
        view
        returns (uint256 amount, uint256 length)
    {
        amount = _totalLocked[locked];
        length = _locks[locked].length;
    }
}