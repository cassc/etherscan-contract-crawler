// contracts/UnlockManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "./common/BaseGovernanceWithUserUpgradable.sol";
import "./interfaces/ILock.sol";

contract LinearUnlockSchedule is BaseGovernanceWithUserUpgradable, IUnlockSchedule {

    uint256 public lockStart;
    uint256 public lockEnd;
    uint256 public cliffTimestamp;

    bool public ownerCanWithdraw;

    ILock public lockContract;

    function initialize(ILock lock, bytes calldata data) public initializer {
        (
            uint256 _lockStartTimestamp, 
            uint256 _lockEndTimestamp, 
            uint256 _cliffTimestamp,
            address governanceAddress
        ) = abi.decode(
            data, 
            (
                uint256,
                uint256,
                uint256,
                address
            )
        );
        __LinearUnlockSchedule_init(lock, _lockStartTimestamp, _lockEndTimestamp, _cliffTimestamp, governanceAddress);
    }

    function __LinearUnlockSchedule_init(ILock _lock, uint256 _lockStartTimestamp, uint256 _lockEndTimestamp, uint256 _cliffTimestamp, address governanceAddress) internal onlyInitializing {
        __BaseGovernanceWithUser_init(governanceAddress);
        __LinearUnlockSchedule_init_unchained(_lock, _lockStartTimestamp, _lockEndTimestamp, _cliffTimestamp);
    }

    function __LinearUnlockSchedule_init_unchained(ILock _lock, uint256 _lockStartTimestamp, uint256 _lockEndTimestamp, uint256 _cliffTimestamp) internal onlyInitializing {
        require(_cliffTimestamp >= _lockStartTimestamp, "cliff before lock start");
        require(_cliffTimestamp <= _lockEndTimestamp, "cliff after lock end");
        require(block.timestamp <= _lockEndTimestamp, "lock end passed");
        lockContract = _lock;
        lockStart = _lockStartTimestamp;
        lockEnd = _lockEndTimestamp;
        cliffTimestamp = _cliffTimestamp;
        ownerCanWithdraw = true;
    }

    /**
     * @notice Calculate the amount of unlocked tokens
     * @dev The lock contract pass the arguments
     * @param initialAmount Initial amount of the lock
     * @return The unlocked tokens
     */
    function unlockedAmount(uint256 initialAmount) external view override returns(uint256) {
        uint256 _unlockedAmount;
        if(block.timestamp < cliffTimestamp) {
            _unlockedAmount = 0;
        } else if (block.timestamp >= lockEnd) {
            _unlockedAmount = initialAmount;
        } else {
            _unlockedAmount = initialAmount * (block.timestamp - lockStart) / (lockEnd - lockStart);
        }
        return _unlockedAmount;
    }

    /**
     * @notice Function that get the withdraw capability for BeneficiaryManager
     * @dev Second argument should return True in EventSchedule and False in all time based schedules
     * @return Tuple ((bool,bool)(ifOwnerCanWithdrawOnLockEnd,trueIfEventUnlockSchedule))
     */
    function withdrawCapability() external view returns(bool,bool){
        return (ownerCanWithdraw, false);
    }

}