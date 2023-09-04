// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";

contract Vesting is Ownable, Pausable {

    // Number of seconds in 365 days, divided by 12:
    uint256 public constant SECONDS_PER_MONTH = 2628000;

    // Mapping of plan id to start date. All beneficiaries of a specific plan would have the same start time
    mapping(uint256 => uint256) public startDates;
    struct VestingSchedule {
        uint256 totalTokens; // amount of tokens for a recipient
        uint256 releasePeriod; // Number of months for the release period
        uint256 startDate; // The plan number for the start time of the vesting schedule
        uint256 releasedTokens; // Number of tokens released so far
        uint256 lockDuration; // Number of months for the release period
    }
    uint256 public tokensVested;

    // privatesale addr => (user addr => schedule)
    mapping(address => mapping(address => VestingSchedule)) public vestingSchedules;

    // privatesale addr => bool
    mapping(address => bool) public vestingSchedulesActive;
    mapping(address => bool) public whitelist;

    IERC20 public token;

    event TokensReleased(address beneficiary, uint256 amount);
    event VestingScheduleCreated(address beneficiary, uint256 totalTokens, uint256 startDate, uint256 lockDuration);
    event VestingScheduleUpdated(address beneficiary, uint256 totalTokens);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function createVestingSchedule(address beneficiary, uint256 totalTokens, uint256 releasePeriod, uint256 startDate, uint256 lockDuration)
        external
        onlyWhitelisted
        whenNotPaused
    {
        require(totalTokens > 0, "Total tokens must be greater than zero");
        require(releasePeriod > 0, "Release period must be greater than zero");
        require((totalTokens + tokensVested) <= token.balanceOf(address(this)), "Not enough tokens for vesting");
        require(
            vestingSchedules[msg.sender][beneficiary].releasedTokens == 0,
            "Vesting schedule already in use, for the beneficiary"
        );
        VestingSchedule storage schedule = vestingSchedules[msg.sender][beneficiary];
        if(vestingSchedules[msg.sender][beneficiary].totalTokens == 0) {
            schedule.totalTokens = totalTokens;
            schedule.releasePeriod = releasePeriod;
            schedule.startDate = startDate;
            schedule.lockDuration = lockDuration;
            emit VestingScheduleCreated(beneficiary, schedule.totalTokens, startDates[schedule.startDate], schedule.lockDuration);
        } else {
            schedule.totalTokens = schedule.totalTokens + totalTokens;
            emit VestingScheduleUpdated(beneficiary, totalTokens);
        }
        tokensVested = tokensVested + totalTokens;
    }

    function removeVestingSchedule(address contractAddress, address beneficiary)
        external
        whenNotPaused
        onlyWhitelisted
    {
        VestingSchedule storage schedule = vestingSchedules[contractAddress][beneficiary];
        uint256 tokensLeft = schedule.totalTokens - schedule.releasedTokens;
        tokensVested = tokensVested - tokensLeft;
        delete vestingSchedules[contractAddress][beneficiary];
    }

    function releaseTokens(address contractAddress, address beneficiary) external whenNotPaused onlyWhitelisted {
        require(vestingSchedulesActive[contractAddress] == true, "Vesting schedule not active");
        uint256 releasableTokens = getReleasableTokens(contractAddress, beneficiary);
        require(releasableTokens > 0, "No tokens available for release");
        VestingSchedule storage schedule = vestingSchedules[contractAddress][beneficiary];
        schedule.releasedTokens = schedule.releasedTokens + releasableTokens;
        tokensVested = tokensVested - releasableTokens;
        token.transfer(beneficiary, releasableTokens);
        emit TokensReleased(beneficiary, releasableTokens);
    }

    function getReleasableTokens(address contractAddress, address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[contractAddress][beneficiary];
        require(schedule.totalTokens > 0, "No vesting schedule found for the beneficiary");
        uint256 tokensToClaim;
        uint256 claimingStartTime = startDates[schedule.startDate] + (schedule.lockDuration * SECONDS_PER_MONTH);
        if(block.timestamp <= claimingStartTime) {
            tokensToClaim = 0;
        } else {
            uint256 elapsedTime = block.timestamp - claimingStartTime;
            uint256 totalReleasePeriods = schedule.releasePeriod;
            uint256 totalTokens = schedule.totalTokens;
            uint256 tokensPerPeriod = totalTokens / totalReleasePeriods;
            uint256 passedMonths = (elapsedTime / SECONDS_PER_MONTH) >= totalReleasePeriods
                ? totalReleasePeriods
                : elapsedTime / SECONDS_PER_MONTH;
            uint256 tokensToRelease = passedMonths * (tokensPerPeriod);

            if(passedMonths == 0) {
                tokensToClaim = 0;
            } else {
                tokensToClaim = passedMonths == totalReleasePeriods
                    ? totalTokens - schedule.releasedTokens
                    : tokensToRelease - schedule.releasedTokens;
            }
        }
        return tokensToClaim;
    }

    function getNextClaimableTime(address contractAddress, address beneficiary, uint256 dateID) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[contractAddress][beneficiary];
        uint256 current_time = block.timestamp;
        uint256 timeRemaining;
        uint256 claimingStartTime = startDates[dateID] + (schedule.lockDuration * SECONDS_PER_MONTH);
        if(current_time > ((schedule.releasePeriod * SECONDS_PER_MONTH) + claimingStartTime)) {
            timeRemaining = 0;
        } else {
            if(current_time >= claimingStartTime) {
                uint256 diff = current_time - claimingStartTime;
                uint256 current_multiple = diff / SECONDS_PER_MONTH;
                uint256 timer_start = (current_multiple * SECONDS_PER_MONTH) + claimingStartTime;
                uint256 current_progress_in_month = current_time - timer_start;
                timeRemaining = SECONDS_PER_MONTH - current_progress_in_month;
            } else {
                timeRemaining = claimingStartTime - current_time;
            }
        }
        return timeRemaining;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Sender is not whitelisted");
        _;
    }

    function updateStartDate(uint256 dateId, uint256 startDate) external onlyOwner {
        startDates[dateId] = startDate;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            whitelist[addr] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            whitelist[addr] = false;
        }
    }

    function setVestingSchedulesActive(address contractAddress, bool active) external onlyOwner {
        vestingSchedulesActive[contractAddress] = active;
    }

    function updateTokenAddress(address tokenAddr) external onlyOwner {
        require(tokenAddr != address(0), "Token address cannot be Zero");
        token = IERC20(tokenAddr);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}