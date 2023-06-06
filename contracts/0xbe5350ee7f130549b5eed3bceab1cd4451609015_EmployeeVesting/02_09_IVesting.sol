// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVesting {
    /**
     * @notice Sets up a vesting schedule for a set user
     * @dev adds a new Schedule to the schedules mapping
     * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
     *                the cliff period.
     * @param amount the amount of tokens being vested for the user.
     * @param isFixed a flag for if the vesting schedule is fixed or not. Fixed vesting schedules can't be cancelled.
     */
    function setVestingSchedule(
        address account,
        uint256 amount,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks
    ) external;

    /**
     * @notice allows users to claim vested tokens if the cliff time has passed
     */
    function claim(uint256 proposalId) external;

    /**
     * @notice Allows a vesting schedule to be cancelled.
     * @dev Any outstanding tokens are returned to the system.
     * @param account the account of the user whos vesting schedule is being cancelled.
     */
    function cancelVesting(address account, uint256 proposalId) external;

    /**
     * @notice returns the total amount and total claimed amount of a users vesting schedule.
     * @param account the user to retrieve the vesting schedule for.
     */
    function getVesting(address account, uint256 proposalId)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice calculates the amount of tokens to distribute to an account at any instance in time, based off some
     *         total claimable amount.
     * @param amount the total outstanding amount to be claimed for this vesting schedule
     * @param currentTime the current timestamp
     * @param startTime the timestamp this vesting schedule started
     * @param endTime the timestamp this vesting schedule ends
     */
    function calcDistribution(
        uint256 amount,
        uint256 currentTime,
        uint256 startTime,
        uint256 endTime
    ) external pure returns (uint256);

    /**
    * @notice Withdraws TCR tokens from the contract.
    * @dev blocks withdrawing locked tokens.
    */
    function withdraw(uint amount) external;
}