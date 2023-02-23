// contracts/interfaces/IUnlockSchedule.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IUnlockSchedule {
    /**
     * @notice Calculate the amount of unlocked tokens
     * @dev The lock contract pass the arguments
     * @param initialAmount Initial amount of the lock
     * @return The unlocked tokens
     */
    function unlockedAmount(uint256 initialAmount) external view returns(uint256);

    /**
    * @notice Function that get the timestamp when the lock was created
    * @return timestamp when the lock start
    */
    function lockStart() external view returns(uint256 timestamp);

    /**
     * @notice Function that get the timestamp when the lock will finish
     * @return timestamp when the lock end
     */
    function lockEnd() external view returns(uint256 timestamp);

    /**
     * @notice Function that get the next timestamp when the lock will be claimable
     * @return timestamp to next release
     */
    function nextRelease() external view returns(uint256 timestamp);

    /**
     * @notice Function that get the bool true if beneficiary manager wants withdraw all remaining amounts on lock end
     * @return bool true in case if owner is beneficiary at lock end
     */
    function withdrawCapability() external view returns(bool,bool);
}