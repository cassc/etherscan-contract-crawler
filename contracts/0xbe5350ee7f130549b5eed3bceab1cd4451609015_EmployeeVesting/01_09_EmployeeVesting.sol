// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVesting.sol";

/**
* Modified Version of the vesting contract that allows the setting of a start date,
* and allows the DAO to control the vesting contract and cancel anyones vesting.
*/
contract EmployeeVesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Schedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        bool isFixed;
        bool cliffClaimed;
    }

    // user => scheduleId => schedule
    mapping(address => mapping(uint256 => Schedule)) public schedules;
    mapping(address => uint256) public numberOfSchedules;

    uint256 public valueLocked;
    IERC20 private TCR;
    address public DAO;

    event Claim(uint256 amount, address claimer);
    event Cancelled(address account);

    constructor(address tcr, address dao) public {
        TCR = IERC20(tcr);
        DAO = dao;
    }

    /**
     * @notice Sets up a vesting schedule for a set user.
     * @dev adds a new Schedule to the schedules mapping.
     * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
     *                the cliff period.
     * @param amount the amount of tokens being vested for the user.
     * @param isFixed a flag for if the vesting schedule is fixed or not. Fixed vesting schedules can't be cancelled.
     * @param cliffWeeks the number of weeks that the cliff will be present at.
     * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
     */
    function setVestingSchedule(
        address account,
        uint256 amount,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks,
        uint256 startTime
    ) public onlyOwner {
        require(
            vestingWeeks >= cliffWeeks,
            "Vesting: cliff after vesting period"
        );
        uint256 currentNumSchedules = numberOfSchedules[account];
        schedules[account][currentNumSchedules] = Schedule(
            amount,
            0,
            startTime,
            startTime.add(cliffWeeks * 1 weeks),
            startTime.add(vestingWeeks * 1 weeks),
            isFixed,
            false
        );
        numberOfSchedules[account] = currentNumSchedules + 1;
        valueLocked = valueLocked.add(amount);
    }

    /**
     * @notice Sets up vesting schedules for multiple users within 1 transaction.
     * @dev adds a new Schedule to the schedules mapping.
     * @param accounts an array of the accounts that the vesting schedules are being set up for.
     *                 Will be able to claim tokens after the cliff period.
     * @param amount an array of the amount of tokens being vested for each user.
     * @param isFixed an array of flags for if each users vesting schedule is fixed or not. Fixed vesting schedules can't be cancelled.
     * @param cliffWeeks an array of the number of weeks that the users cliff will be present at.
     * @param vestingWeeks an array of the number of weeks the each users tokens will vest over (linearly)
     */
    function setVestingSchedules(
        address[] calldata accounts,
        uint256[] calldata amount,
        bool[] calldata isFixed,
        uint256[] calldata cliffWeeks,
        uint256[] calldata vestingWeeks,
        uint256[] calldata startTimes
    ) public onlyOwner {
        uint256 numberOfAccounts = accounts.length;
        require(
            amount.length == numberOfAccounts &&
                isFixed.length == numberOfAccounts &&
                cliffWeeks.length == numberOfAccounts &&
                vestingWeeks.length == numberOfAccounts && 
                startTimes.length == numberOfAccounts,
            "Vesting: Array lengths differ"
        );
        for (uint256 i = 0; i < numberOfAccounts; i++) {
            setVestingSchedule(
                accounts[i],
                amount[i],
                isFixed[i],
                cliffWeeks[i],
                vestingWeeks[i],
                startTimes[i]
            );
        }
    }

    /**
     * @notice allows users to claim vested tokens if the cliff time has passed.
     * @param scheduleNumber which schedule the user is claiming against
     */
    function claim(uint256 scheduleNumber) public {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            schedule.cliffTime <= block.timestamp,
            "Vesting: cliffTime not reached"
        );
        require(schedule.totalAmount > 0, "Vesting: No claimable tokens");

        // Get the amount to be distributed
        uint256 amount =
            calcDistribution(
                schedule.totalAmount,
                block.timestamp,
                schedule.startTime,
                schedule.endTime
            );

        // Cap the amount at the total amount
        amount = amount > schedule.totalAmount ? schedule.totalAmount : amount;
        uint256 amountToTransfer = amount.sub(schedule.claimedAmount);
        schedule.claimedAmount = amount; // set new claimed amount based off the curve
        valueLocked = valueLocked.sub(amountToTransfer);
        TCR.safeTransfer(msg.sender, amountToTransfer);
        emit Claim(amount, msg.sender);
    }

    /**
     * @notice Allows a vesting schedule to be cancelled.
     * @dev Any outstanding tokens are returned to the system.
     * @param account the account of the user whos vesting schedule is being cancelled.
     */
    function cancelVesting(address account, uint256 scheduleId)
        public
        onlyDAO
    {
        Schedule storage schedule = schedules[account][scheduleId];
        require(
            schedule.claimedAmount < schedule.totalAmount,
            "Vesting: Tokens fully claimed"
        );
        require(!schedule.isFixed, "Vesting: Account is fixed");
        uint256 outstandingAmount =
            schedule.totalAmount.sub(schedule.claimedAmount);
        schedule.totalAmount = 0;
        valueLocked = valueLocked.sub(outstandingAmount);
        emit Cancelled(account);
    }

    /**
     * @return returns the total amount and total claimed amount of a users vesting schedule.
     * @param account the user to retrieve the vesting schedule for.
     * @param scheduleId the id of the schedule to view
     */
    function getVesting(address account, uint256 scheduleId)
        public
        view
        returns (uint256, uint256)
    {
        Schedule memory schedule = schedules[account][scheduleId];
        return (schedule.totalAmount, schedule.claimedAmount);
    }

    /**
     * @return calculates the amount of tokens to distribute to an account at any instance in time, based off some
     *         total claimable amount.
     * @param amount the total outstanding amount to be claimed for this vesting schedule.
     * @param currentTime the current timestamp.
     * @param startTime the timestamp this vesting schedule started.
     * @param endTime the timestamp this vesting schedule ends.
     */
    function calcDistribution(
        uint256 amount,
        uint256 currentTime,
        uint256 startTime,
        uint256 endTime
    ) public pure returns (uint256) {
        return
            amount.mul(currentTime.sub(startTime)).div(endTime.sub(startTime));
    }

    /**
     * @notice Withdraws TCR tokens from the contract.
     * @dev blocks withdrawing locked tokens.
     */
    function withdraw(uint256 amount) public onlyOwner {
        require(
            TCR.balanceOf(address(this)).sub(valueLocked) >= amount,
            "Vesting: amount > tokens leftover"
        );
        TCR.safeTransfer(owner(), amount);
    }

    /**
     * @notice sets the address of the Tracer DAO.
     */
    function setDAOAddress(address DAOAddress) public onlyOwner {
        DAO = DAOAddress;
    }

    modifier onlyDAO() {
        require(msg.sender == address(DAO), "Vesting: Caller not DAO");
        _;
    }
}