// contracts/UnlockManager.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "./common/BaseGovernanceWithUserUpgradable.sol";
import "./interfaces/ILock.sol";

contract IntervalUnlockSchedule is BaseGovernanceWithUserUpgradable, IUnlockSchedule {
    uint256 constant EXP = 1e18;
    uint256[] keyPoints;
    uint256[] amounts;

    bool public ownerCanWithdraw;

    ILock public lockContract;


    function initialize(ILock lock, bytes calldata data) public initializer {
        (
            uint256[] memory _keyPoints, 
            uint256[] memory _amounts, 
            address governanceAddress
        ) = abi.decode(
            data, 
            (
                uint256[], 
                uint256[],
                address
            )
        );
        __IntervalUnlockSchedule_init(lock, _keyPoints, _amounts, governanceAddress);
    }

    function __IntervalUnlockSchedule_init(ILock _lock, uint256[] memory _keyPoints, uint256[] memory _amounts, address governanceAddress) internal onlyInitializing {
        __BaseGovernanceWithUser_init(governanceAddress);
        __IntervalUnlockSchedule_init_unchained(_lock, _keyPoints, _amounts);
    }

    function __IntervalUnlockSchedule_init_unchained(ILock _lock, uint256[] memory _keyPoints, uint256[] memory _amounts) internal onlyInitializing {
        require(_keyPoints.length >= 2, "ERROR: Need more key points");
        require(_keyPoints.length == _amounts.length, "ERROR: Lenght of KeyPoints and amounts must be equal");
        require(_checkAmounts(_amounts), "ERROR: Amount are not correctly normalized");
        require(_checkKeyPoints(_keyPoints), "ERROR: Key Points are not correctly created");
        lockContract = _lock;
        keyPoints = _keyPoints;
        amounts = _amounts;
        ownerCanWithdraw = true;
    }
    
    /**
     * @notice Calculate the amount of unlocked tokens
     * @dev The lock contract pass the arguments
     * @param _initialAmount Initial amount of the lock
     * @return _unlockedAmount The unlocked tokens
     */
    function unlockedAmount(uint256 _initialAmount) external view override returns(uint256) {
        if(block.timestamp < keyPoints[0]) {
            return 0;
        }
        if(block.timestamp > keyPoints[keyPoints.length - 1]) {
            return _initialAmount;
        }

        uint256 unlockedNormalized;
        for(uint256 i; i < amounts.length;) {
            if(block.timestamp < keyPoints[i]) break;
            unlockedNormalized += amounts[i];
            unchecked {
                ++i;
            }
        }

        return _initialAmount * unlockedNormalized / EXP;
    }
    
    function lockStart() public view override returns(uint256) {
        return keyPoints[0];
    }

    /**
     * @notice Function that get the timestamp when the lock will finish
     * @return Timestamp when the lock end
     */
    function lockEnd() external view override returns(uint) {
        return keyPoints[keyPoints.length - 1];
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

    function _checkKeyPoints(uint256[] memory _keyPoints) internal view returns(bool) {
        for(uint256 i; i < _keyPoints.length - 1;) {
            if(_keyPoints[i] < block.timestamp || _keyPoints[i] > _keyPoints[i + 1]) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }
}