// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
@notice Contract with convenience modifiers for ensuring functions cannot be called until after a certain block.timestamp.
Note: miners/validators can misreport block.timestamp, but discrepancies would be in the magnitude of seconds or maybe minutes, not hours or days.
*/
contract TimeLock is Ownable {
    uint256 public unlockTime;

    event UpdateUnlockTime(uint256 oldUnlockTime, uint256 newUnlockTime);

    error TimeLocked();

    constructor(uint256 _unlockTime) {
        unlockTime = _unlockTime;
    }

    ///@notice will revert if block.timestamp is before unlockTime
    modifier onlyAfterUnlock() {
        if (block.timestamp < unlockTime) {
            revert TimeLocked();
        }
        _;
    }

    function isUnlocked() public virtual returns (bool) {
        return block.timestamp >= unlockTime;
    }

    ///@notice set unlock time. OnlyOwner
    ///@param _unlockTime epoch timestamp in seconds
    function setUnlockTime(uint256 _unlockTime) external onlyOwner {
        emit UpdateUnlockTime(unlockTime, unlockTime = _unlockTime);
    }
}