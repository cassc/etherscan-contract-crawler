// contracts/RealmTeamVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { BokkyPooBahsDateTimeLibrary } from "./BokkyPooBahsDateTimeLibrary.sol";

contract RealmContinuousVesting is AccessControlEnumerable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant SCHEDULER_ROLE = keccak256("SCHEDULER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event AllocationClaimed(address beneficiary, uint256 amount);

    struct Schedule {
        address beneficiary;
        uint256 startTimestamp;
        uint256 duration;
        uint256 totalReleaseAmount; // of all tokens for this schedule
        uint256 lastClaimedTimestamp;
    }

    IERC20 public token;
    mapping(address => Schedule) public vestingSchedules; // addressed by beneficiary
    EnumerableSet.AddressSet internal beneficiaries;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `SCHEDULER_ROLE` and `PAUSER_ROLE`
     * to the account that deploys the contract. Safe Address is the GNOSIS safe (MultiSig) address which would used in order to control the schedules. 
     */
    constructor(address _tokenAddress, address _safeAddress, Schedule[] memory _schedules) {
        _setupRole(DEFAULT_ADMIN_ROLE, _safeAddress);
        _setupRole(SCHEDULER_ROLE, _safeAddress);
        _setupRole(PAUSER_ROLE, _safeAddress);

        uint256 len = _schedules.length;
        for (uint256 i = 0; i < len; i++) {
            _addSchedule(
                _schedules[i].beneficiary
                , _schedules[i].startTimestamp
                , _schedules[i].duration
                , _schedules[i].totalReleaseAmount
                , _schedules[i].lastClaimedTimestamp
            );
        }

        token = IERC20(_tokenAddress);
    }

    function addSchedule(Schedule calldata _schedule) public {
        require(hasRole(SCHEDULER_ROLE, _msgSender()), "Must have scheduler role to add schedule!");
        _addSchedule(
            _schedule.beneficiary
            , _schedule.startTimestamp
            , _schedule.duration
            , _schedule.totalReleaseAmount
            , _schedule.lastClaimedTimestamp
        );
    }

    function addSchedulesBatch(Schedule[] calldata _schedules) public {
        require(hasRole(SCHEDULER_ROLE, _msgSender()), "Must have scheduler role to add schedule!");
        uint256 len = _schedules.length;
        for (uint256 i = 0; i < len; i++) {
            _addSchedule(
                _schedules[i].beneficiary
                , _schedules[i].startTimestamp
                , _schedules[i].duration
                , _schedules[i].totalReleaseAmount
                , _schedules[i].lastClaimedTimestamp
            );
        }
    }

    function _addSchedule(
        address _beneficiary
        , uint256 _startTimestamp
        , uint256 _duration
        , uint256 _totalReleaseAmount
        , uint256 _lastClaimedTimestamp
    ) private {
        vestingSchedules[_beneficiary].beneficiary = _beneficiary;
        vestingSchedules[_beneficiary].startTimestamp = _startTimestamp;
        vestingSchedules[_beneficiary].duration = _duration;
        vestingSchedules[_beneficiary].totalReleaseAmount = _totalReleaseAmount;
        vestingSchedules[_beneficiary].lastClaimedTimestamp = _lastClaimedTimestamp;

        beneficiaries.add(_beneficiary);
    }

    function removeSchedule(address _beneficiary) public {
        require(hasRole(SCHEDULER_ROLE, _msgSender()), "Must have scheduler role to remove schedule!");
        _removeSchedule(_beneficiary);
    }

    function removeSchedulesBatch(address[] calldata _beneficiaries) public {
        require(hasRole(SCHEDULER_ROLE, _msgSender()), "Must have scheduler role to remove schedule!");
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; i++) {
            _removeSchedule(_beneficiaries[i]);
        }
    }

    function _removeSchedule(address _beneficiary) private {
        delete vestingSchedules[_beneficiary];
        beneficiaries.remove(_beneficiary);
    }

    function getAllBeneficiaries() public view returns (address[] memory _beneficiaries) {
        uint256 len = beneficiaries.length();
        _beneficiaries = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            _beneficiaries[i] = beneficiaries.at(i);
        }
        return _beneficiaries;
    }

    function getSchedules(address[] calldata _beneficiaries) public view returns (Schedule[] memory _schedules) {
        uint256 len = _beneficiaries.length;
        _schedules = new Schedule[](len);
        for (uint256 i = 0; i < len; i++) {
            _schedules[i] = vestingSchedules[_beneficiaries[i]];
        }
        return _schedules;
    }

    function calculateAllocation(address beneficiary) public view returns(uint256) {
        Schedule memory schedule = vestingSchedules[beneficiary];

        require(schedule.startTimestamp != 0, "Schedule for beneficiary not found");
        require(schedule.startTimestamp <= block.timestamp, "Schedule hasn't started yet");

        if(schedule.lastClaimedTimestamp == 0) schedule.lastClaimedTimestamp = schedule.startTimestamp;

        // Claimed duration days till date of request. If duration days are greater then decided duration then set calimed to maximum duration days.
        // Also, check if lastclaimed and start time stamp is same then no tokens were vested thus setting to 0.
        uint256 claimedDurationdays = diffDays(schedule.startTimestamp, schedule.lastClaimedTimestamp);
        if(claimedDurationdays > schedule.duration) claimedDurationdays = schedule.duration;
        if(schedule.lastClaimedTimestamp == schedule.startTimestamp) claimedDurationdays = 0; 
        
        // Calculate total duration from the start.
        // If total duartion is greater then the schedule duration set total duraiton to scheule duration
        uint256 totalDurationdays = diffDays(schedule.startTimestamp, block.timestamp);
        if(totalDurationdays > schedule.duration) totalDurationdays = schedule.duration;

        // Calcuate the remaining duration days for vesting
        uint256 unclaimedDurationdays = totalDurationdays - claimedDurationdays;

        require(unclaimedDurationdays > 0, "Beneficiary doesn't have any unclaimed vesting duration");
        if(unclaimedDurationdays > schedule.duration) unclaimedDurationdays = schedule.duration;

        uint256 releaseAmount = (schedule.totalReleaseAmount * unclaimedDurationdays).div(schedule.duration);
        return releaseAmount;
    }
    
    // claim your vested allocation
    // should be able to allocate without multisig
    function claimAllocation() public whenNotPaused {
        address sender = _msgSender();
        Schedule storage schedule = vestingSchedules[sender];

        uint256 releaseAmount = calculateAllocation(sender);
        uint256 contractBalance = token.balanceOf(address(this));
        
        // since we have decimal of 10**18
        require(releaseAmount <= contractBalance, "Not enough tokens in contract for release amount");

        // send tokens / add allowance on token contract
        schedule.lastClaimedTimestamp = block.timestamp;
        
        //token.safeIncreaseAllowance(sender, releaseAmount);
        token.safeTransfer(sender, releaseAmount);
        emit AllocationClaimed(sender, releaseAmount);
    }
    
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }

    /**
     * @dev Pauses all allocation claims (token payouts).
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all allocation claims (token payouts).
     * See {Pausable-_unpause}.
     *
     * Requirements:
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to unpause");
        _unpause();
    }
}