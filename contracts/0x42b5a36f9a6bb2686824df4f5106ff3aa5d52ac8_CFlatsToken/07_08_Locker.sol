// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Locker {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _UNLOCKED = 1;
    uint256 private constant _LOCKED = 2;

    uint256 private _delay;
    uint256 private _status;

    constructor() {
        _status = _UNLOCKED;
    }

    /**
     * @dev Locks the function untill it wouldn't be unlocked 
     */
    modifier lock() {
        _lock();
        _;
    }


    /**
     * @dev Locks the function untill it wouldn't be unlocked 
     */
    modifier lockWithDelay(uint256 delay) {
        uint256 currentTime = block.timestamp;
        uint256 nextAprrovedDelay = currentTime + delay;

        if(isLocked() == false)
        {
            _delay = nextAprrovedDelay;
            _lock();
            _;
        }
        else
        {
            require(_delay <= currentTime, "Locker: this function is locked!");
            
            _unlock();
            _delay = nextAprrovedDelay;

            _lock();
            _;
        }
    }


    /**
     * @dev Unlocks the function 
     */
    modifier unlock() {
        _unlock();
        _;
    }


    function isLocked() public virtual view returns (bool)
    {
        return _status == _LOCKED;
    }

    function _lock() private {
        // Verify if status is not locked otherwise exit function
        require(_status != _LOCKED, "Locker: this function is locked!");

        // Any calls to lock after this point will fail
        _status = _LOCKED;
    }


    function _unlock() private {
        // Verify if status is not locked otherwise exit function
        require(_status != _UNLOCKED, "Locker: this function is not locked!");

        _status = _UNLOCKED;
    }
}