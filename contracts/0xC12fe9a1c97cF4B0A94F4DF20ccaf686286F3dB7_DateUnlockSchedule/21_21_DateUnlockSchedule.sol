// contracts/UnlockManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../common/BaseGovernanceWithUserUpgradable.sol";
import "../interfaces/ILock.sol";

contract DateUnlockSchedule is BaseGovernanceWithUserUpgradable, IUnlockSchedule {

    uint256[] public normalizedAmounts;
    uint256[] public unlockTimestamps;
    uint256 internal constant EXP = 1e18;

    bool public ownerCanWithdraw;

    ILock public lockContract;

    event DateUnlockScheduleInitialized(address);

    function initialize(ILock lock, bytes calldata data) public initializer {
        __DateUnlockSchedule_init(lock, data);
    }

    function __DateUnlockSchedule_init(ILock _lock, bytes calldata _data) internal onlyInitializing {
        __DateUnlockSchedule_init_unchained(_lock, _data);
    }

    function __DateUnlockSchedule_init_unchained(ILock _lock, bytes calldata _data) internal onlyInitializing {
        (
            uint256[] memory _normalizedAmounts, 
            uint256[] memory _unlockTimestamps,
            address governanceAddress
        ) = abi.decode(
            _data, 
            (
                uint256[], 
                uint256[],
                address
            )
        );
        __BaseGovernanceWithUser_init(governanceAddress);
        _setupRole(GOVERNANCE_ROLE, governanceAddress); // Check if this is correct
        
        require(_unlockTimestamps.length >= 2, "ERROR: Need more unlock timestamps");
        require(_unlockTimestamps.length == _normalizedAmounts.length, "ERROR: Lenght of KeyPoints and amounts must be equal");
        require(_checkAmounts(_normalizedAmounts), "ERROR: Amount are not correctly normalized");
        require(_checkUnlockTimes(_unlockTimestamps), "ERROR: Key Points are not correctly created");
        lockContract = _lock;
        normalizedAmounts = _normalizedAmounts;
        unlockTimestamps = _unlockTimestamps;
        ownerCanWithdraw = true;
        emit DateUnlockScheduleInitialized(address(this));
    }

    /**
     * @notice Calculate the amount of unlocked tokens
     * @dev The lock contract pass the arguments
     * @param initialAmount Initial amount of the lock
     * @return The unlocked tokens
     */
    function unlockedAmount(uint256 initialAmount) external override view returns(uint256) {
        if(block.timestamp < unlockTimestamps[0]) {
            return  0;
        } else if (block.timestamp >= lockEnd()) {
            return  initialAmount;
        } else {
            uint256 normalizedUnlockedSumm = 0;
            for(uint256 i; i < unlockTimestamps.length;){
                if(block.timestamp < unlockTimestamps[i]){
                    break;
                }
                normalizedUnlockedSumm += normalizedAmounts[i];  
                unchecked {
                    ++i;
                } 
            }
            return initialAmount * normalizedUnlockedSumm / EXP;
        }
    }

    function lockStart() public view override returns(uint256) {
        return unlockTimestamps[0];
    }

    /**
     * @notice Function that get the timestamp when the lock will finish
     * @return Timestamp when the lock end
     */
    function lockEnd() public view override returns(uint256) {
        return unlockTimestamps[unlockTimestamps.length - 1];
    }

    /**
     * @notice Function that get the next timestamp when the lock will be claimable
     * @return timestamp to next release
     */
    function nextRelease() external view returns(uint256 timestamp) {
        for(uint256 i; i < unlockTimestamps.length; ) {
            if(unlockTimestamps[i] > block.timestamp) return timestamp = unlockTimestamps[i];
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

    function _checkAmounts(uint256[] memory _amounts) internal pure returns(bool) {
        uint256 total;
        for(uint256 i; i < _amounts.length;) {
            total += _amounts[i];
            unchecked {
                ++i;
            }
        }
        return total == EXP;
    }

    function _checkUnlockTimes(uint256[] memory _unlockTimes) internal view returns(bool) {
        for(uint256 i; i < _unlockTimes.length - 1;) {
            if(_unlockTimes[i] < block.timestamp || _unlockTimes[i] > _unlockTimes[i + 1]) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

}