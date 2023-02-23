// contracts/UnlockManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../common/BaseGovernanceWithUserUpgradable.sol";
import "../interfaces/ILock.sol";

contract EqualUnlockSchedule is BaseGovernanceWithUserUpgradable, IUnlockSchedule {

    uint256 public lockStart;
    uint256 public lockLenght;
    uint256 public unlockPeriod;
    uint256 public totalPeriods;

    bool public ownerCanWithdraw;

    ILock public lockContract;

    event EqualUnlockScheduleInitialized(address);

    function initialize(ILock lock, bytes calldata data) public initializer {
        __EqualUnlockSchedule_init(lock, data);
    }

    function __EqualUnlockSchedule_init(ILock _lock, bytes calldata _data) internal onlyInitializing {
        __EqualUnlockSchedule_init_unchained(_lock, _data);
    }

    function __EqualUnlockSchedule_init_unchained(ILock _lock, bytes calldata _data) internal onlyInitializing {
        (
            uint256 _lockStart,
            uint256 _lockLenght, 
            uint256 _unlockPeriod,
            address governanceAddress
        ) = abi.decode(
            _data, 
            (
                uint256,
                uint256, 
                uint256,
                address
            )
        );
        __BaseGovernanceWithUser_init(governanceAddress);
        _setupRole(GOVERNANCE_ROLE, governanceAddress); // Check if this is correct
        require(_lockLenght > 0, "ERROR: The Lock lenght is zero");
        require(_unlockPeriod > 0, "ERROR: The unlock period should not be zero");
        lockContract = _lock;
        lockStart = _lockStart;
        lockLenght = _lockLenght;
        unlockPeriod = _unlockPeriod;

        totalPeriods = lockLenght / unlockPeriod; // Will be rounded to floor, so it will be count of full periods
        if(lockLenght % unlockPeriod != 0) totalPeriods++; //add possible partial period at the end of lock time
        
        ownerCanWithdraw = true;
        emit EqualUnlockScheduleInitialized(address(this));
    }

    /**
     * @notice Calculate the amount of unlocked tokens
     * @dev The lock contract pass the arguments
     * @param initialAmount Initial amount of the lock
     * @return The unlocked tokens
     */
    function unlockedAmount(uint256 initialAmount) external view override returns(uint256) {
        if(block.timestamp < (lockStart + unlockPeriod)) {
            return 0;
        }
        if(block.timestamp >= lockEnd()) {
            return initialAmount;
        }
        uint256 timePassedSinceStart = block.timestamp - lockStart;
        uint256 passedPeriods = timePassedSinceStart / unlockPeriod; // Will be rounded to floor, so it will be count of fully passed periods
        return ((initialAmount * passedPeriods) / totalPeriods);    // This may result in rounding, but everything will be correct after endLockTime()
    }

    /**
     * @notice Function that get the timestamp when the lock will finish
     * @return Timestamp when the lock end
     */
    function lockEnd() public view override returns(uint256) {
        return lockStart+lockLenght;
    }

    /**
     * @notice Function that get the next timestamp when the lock will be claimable
     * @return timestamp to next release
     */
    function nextRelease() external view returns(uint256 timestamp) {
        timestamp = lockStart;
        for(uint256 i; i < totalPeriods; ) {
            timestamp += unlockPeriod;
            if(timestamp > block.timestamp) return timestamp;
            unchecked {
                i++;
            }
        }
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