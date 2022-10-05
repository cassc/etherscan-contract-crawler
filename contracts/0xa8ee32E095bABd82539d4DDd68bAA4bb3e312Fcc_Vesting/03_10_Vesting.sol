// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting is Ownable {
    /**
     * @notice The structure is used in the contract createVestingScheduleBatch function to create vesting schedules
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param isStandard is the schedule standard type
     * @param percentsPerStages token percentages for each stage to be vest(% * 100). Empty array if schedule is standard
     * @param stagePeriods schedule stages in minutes(block.timestamp / 60). Empty array if schedule is standard
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        bool isStandard;
        uint16[] percentsPerStages;
        uint32[] stagePeriods;
    }

    /**
     * @notice Standard vesting schedules of an account.
     * @param initialized to check whether such a schedule already exists or not.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param activeStage index of the stage starting from which tokens were not withdrawn.
     */
    struct StandardVestingSchedule {
        bool initialized;
        uint256 totalAmount;
        uint256 released;
        uint16 activeStage;
    }

    /**
     * @notice Non standard vesting schedules of an account.
     * @param initialized to check whether such a schedule already exists or not.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param activeStage index of the stage starting from which tokens were not withdrawn.
     * @param percentsPerStages token percentages for each stage to be vest(% * 100).
     * @param stagePeriods schedule stages in minutes(block.timestamp / 60).
     */
    struct NonStandardVestingSchedule {
        bool initialized;
        uint256 totalAmount;
        uint256 released;
        uint16 activeStage;
        uint16[] percentsPerStages;
        uint32[] stagePeriods;
    }

    mapping(address => StandardVestingSchedule) public standardSchedules;
    mapping(address => NonStandardVestingSchedule) public nonStandardSchedules;

    IERC20 public immutable token;

    /// @notice token percentages for standard schedules for each stage to be vest. Percent multiplied by 100
    uint16[9] public percentsPerStages = [3000, 750, 750, 750, 750, 1000, 1000, 1000, 1000];
    /// @notice standard schedule stages in minutes. block.timestamp / 60
    uint32[9] public stagePeriods = [
        28381500,
        28512540,
        28645020,
        28777500,
        28908540,
        29038140,
        29170620,
        29303100,
        29434140
    ];

    event NewSchedule(address target, bool isStandard);
    event Withdrawal(address target, uint256 amount, bool isStandard);
    event EmergencyWithdrawal(address target, uint256 amount, bool isStandard);
    event UpdatedScheduleTarget(address oldTarget, address newTarget);

    constructor(IERC20 _token) {
        token = _token;
    }

    /**
     * @notice early withdraw tokens to owner address (in case if something goes wrong)
     * @param target withdrawal schedule target address
     */
    function emergencyWithdraw(address target) external onlyOwner {
        require(_isScheduleExist(target), "Vesting::MISSING_SCHEDULE");

        if (standardSchedules[target].initialized) {
            StandardVestingSchedule memory schedule = standardSchedules[target];

            delete standardSchedules[target];
            emit EmergencyWithdrawal(target, schedule.totalAmount - schedule.released, true);
            require(token.transfer(msg.sender, schedule.totalAmount - schedule.released));
        } else {
            NonStandardVestingSchedule memory schedule = nonStandardSchedules[target];

            delete nonStandardSchedules[target];
            emit EmergencyWithdrawal(target, schedule.totalAmount - schedule.released, false);
            require(token.transfer(msg.sender, schedule.totalAmount - schedule.released));
        }
    }

    /**
     * @notice create a new vesting schedules.
     * @param schedulesData an array of vesting schedules that will be created.
     */
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external onlyOwner {
        uint256 length = schedulesData.length;
        uint256 tokenAmount;

        for (uint256 i = 0; i < length; i++) {
            ScheduleData memory schedule = schedulesData[i];

            tokenAmount += schedule.totalAmount;

            _isValidSchedule(schedule);
            require(!_isScheduleExist(schedule.target), "Vesting::EXISTING_SCHEDULE");

            _createVestingSchedule(schedule);
        }

        require(token.transferFrom(msg.sender, address(this), tokenAmount));
    }

    /**
     * @notice claim available (unlocked) tokens
     * @param target withdrawal schedule target address.
     */
    function withdraw(address target) external {
        require(_isScheduleExist(target), "Vesting::MISSING_SCHEDULE");

        bool isStandard = standardSchedules[target].initialized;
        uint256 amount;

        if (isStandard) {
            amount = _withdrawStandard(target, getTime());
        } else {
            amount = _withdrawNonStandard(target, getTime());
        }

        emit Withdrawal(target, amount, isStandard);

        require(token.transfer(target, amount));
    }

    /**
     * @notice update schedule target address
     * @param from old target address.
     * @param to new target address.
     */
    function updateTarget(address from, address to) external {
        require(msg.sender == owner() || msg.sender == from, "Vesting::FORBIDDEN");
        require(!_isScheduleExist(to), "Vesting::EXISTING_SCHEDULE");

        bool isStandard = standardSchedules[from].initialized;
        if (isStandard) {
            standardSchedules[to] = standardSchedules[from];
            delete standardSchedules[from];
        } else {
            nonStandardSchedules[to] = nonStandardSchedules[from];
            delete nonStandardSchedules[from];
        }
        emit UpdatedScheduleTarget(from, to);
    }

    /**
     * @notice withdraw stuck tokens
     * @param _token token for withdraw.
     * @param _amount amount of tokens.
     */
    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyOwner {
        require(address(token) != _token, "Vesting::FORBIDDEN");

        require(IERC20(_token).transfer(msg.sender, _amount));
    }

    /**
     * @notice get the amount of tokens available for withdrawal
     * @param target withdrawal schedule target address
     */
    function claimableAmount(address target) external view returns (uint256 amount) {
        require(_isScheduleExist(target), "Vesting::MISSING_SCHEDULE");
        uint16 stage;

        if (standardSchedules[target].initialized) {
            StandardVestingSchedule memory schedule = standardSchedules[target];

            for (stage = schedule.activeStage; stage < stagePeriods.length; stage++) {
                if (getTime() >= stagePeriods[stage]) {
                    amount += (percentsPerStages[stage] * schedule.totalAmount) / 10000;
                } else break;
            }
        } else {
            NonStandardVestingSchedule memory schedule = nonStandardSchedules[target];

            for (stage = schedule.activeStage; stage < schedule.stagePeriods.length; stage++) {
                if (getTime() >= schedule.stagePeriods[stage]) {
                    amount += (schedule.percentsPerStages[stage] * schedule.totalAmount) / 10000;
                } else break;
            }
        }
    }

    function getSchedulePercents(address target) external view returns (uint16[] memory) {
        return nonStandardSchedules[target].percentsPerStages;
    }

    function getScheduleStagePeriods(address target) external view returns (uint32[] memory) {
        return nonStandardSchedules[target].stagePeriods;
    }

    function getTime() internal view virtual returns (uint32) {
        return uint32(block.timestamp / 60);
    }

    function _withdrawStandard(address target, uint32 time) private returns (uint256 amount) {
        StandardVestingSchedule memory schedule = standardSchedules[target];
        require(stagePeriods[schedule.activeStage] <= time, "Vesting::TOO_EARLY");
        uint16 stage;

        for (stage = schedule.activeStage; stage < stagePeriods.length; stage++) {
            if (time >= stagePeriods[stage]) {
                amount += (percentsPerStages[stage] * schedule.totalAmount) / 10000;
            } else break;
        }

        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released + amount == schedule.totalAmount) {
            delete standardSchedules[target];
            return amount;
        }
        standardSchedules[target].released += amount;
        standardSchedules[target].activeStage = stage;
    }

    function _withdrawNonStandard(address target, uint32 time) private returns (uint256 amount) {
        NonStandardVestingSchedule memory schedule = nonStandardSchedules[target];
        require(schedule.stagePeriods[schedule.activeStage] <= time, "Vesting::TOO_EARLY");
        uint16 stage;

        for (stage = schedule.activeStage; stage < schedule.stagePeriods.length; stage++) {
            if (time >= schedule.stagePeriods[stage]) {
                amount += (schedule.percentsPerStages[stage] * schedule.totalAmount) / 10000;
            } else break;
        }

        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released + amount == schedule.totalAmount) {
            delete nonStandardSchedules[target];
            return amount;
        }
        nonStandardSchedules[target].released += amount;
        nonStandardSchedules[target].activeStage = stage;
    }

    function _isValidSchedule(ScheduleData memory schedule_) private pure {
        require(schedule_.target != address(0), "Vesting::ZERO_TARGET");
        require(schedule_.totalAmount > 0, "Vesting::ZERO_AMOUNT");
        if (!schedule_.isStandard) {
            require((schedule_.percentsPerStages).length > 0, "Vesting::MISSING_STAGES");
            require(
                (schedule_.percentsPerStages).length == (schedule_.stagePeriods).length,
                "Vesting::INVALID_PERCENTS_OR_STAGES"
            );
            uint256 totalPercents;
            for (uint256 i = 0; i < (schedule_.percentsPerStages).length; i++) {
                totalPercents += schedule_.percentsPerStages[i];
            }
            require(totalPercents == 10000, "Vesting::INVALID_PERCENTS");
        }
    }

    function _isScheduleExist(address scheduleTarget) private view returns (bool) {
        return standardSchedules[scheduleTarget].initialized || nonStandardSchedules[scheduleTarget].initialized;
    }

    function _createVestingSchedule(ScheduleData memory scheduleData) private {
        if (scheduleData.isStandard) {
            _createStandardVestingSchedule(scheduleData);
        } else {
            _createNonStandardVestingSchedule(scheduleData);
        }
    }

    function _createStandardVestingSchedule(ScheduleData memory scheduleData) private {
        standardSchedules[scheduleData.target] = StandardVestingSchedule({
            initialized: true,
            totalAmount: scheduleData.totalAmount,
            released: 0,
            activeStage: 0
        });
        emit NewSchedule(scheduleData.target, true);
    }

    function _createNonStandardVestingSchedule(ScheduleData memory scheduleData) private {
        nonStandardSchedules[scheduleData.target] = NonStandardVestingSchedule({
            initialized: true,
            totalAmount: scheduleData.totalAmount,
            released: 0,
            activeStage: 0,
            percentsPerStages: scheduleData.percentsPerStages,
            stagePeriods: scheduleData.stagePeriods
        });
        emit NewSchedule(scheduleData.target, false);
    }
}