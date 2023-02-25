// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is ReentrancyGuard, Ownable{
    IERC20 public token;
    
    struct VestingSchedule{
        address receiver;
        uint256 start; // start time of the vesting period
        uint256 end; // end time of the vesting period
        uint256 amount;
        uint256 portionReleasedByMonth; // 24 for this example: over 24 months, once a month
        uint256 amountReleased;
    }

    VestingSchedule[] public vestingSchedules;

    event ReleaseSuccessful(address receiver, uint256 amount);

    constructor(address _owner, address _token) {
        require(_token != address(0x0));
        token = IERC20(_token);
        _transferOwnership(_owner);
    }

    function createVestingSchedule(address _receiver, uint256 _end, uint256 _amount, uint256 _portionReleasedByMonth) public onlyOwner nonReentrant {
        require(_amount > 0, "TokenVesting: amount must be > 0");
        token.transferFrom(msg.sender, address(this), _amount);
        vestingSchedules.push(VestingSchedule(_receiver, block.timestamp, _end, _amount, _portionReleasedByMonth, 0));
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 _vestingSchedulesSize = vestingSchedules.length;

        for(uint256 i = 0; i < _vestingSchedulesSize;) {
            if (vestingSchedules[i].amountReleased < vestingSchedules[i].amount) {
                if (vestingSchedules[i].portionReleasedByMonth == 0) { // one time release
                    if (vestingSchedules[i].end < block.timestamp) {
                        vestingSchedules[i].amountReleased = vestingSchedules[i].amount;
                        token.transfer(vestingSchedules[i].receiver, vestingSchedules[i].amount);

                        emit ReleaseSuccessful(vestingSchedules[i].receiver, vestingSchedules[i].amount);
                    }
                } else { // monthly release
                    uint256 _timePassedSinceLock = block.timestamp - vestingSchedules[i].start;
                    uint256 _secondsInAMonth = 2_628_288;
                    uint256 _monthsPassedSinceLock = _timePassedSinceLock / _secondsInAMonth;

                    uint256 _amountAllowedForRelease = _monthsPassedSinceLock * vestingSchedules[i].amount / vestingSchedules[i].portionReleasedByMonth;
                    if (_amountAllowedForRelease > vestingSchedules[i].amountReleased) {
                        uint256 _differenceAmountToRelease = _amountAllowedForRelease - vestingSchedules[i].amountReleased;
                        
                        vestingSchedules[i].amountReleased += _differenceAmountToRelease;
                        token.transfer(vestingSchedules[i].receiver, _differenceAmountToRelease);

                        emit ReleaseSuccessful(vestingSchedules[i].receiver, _differenceAmountToRelease);
                    }
                }
            }
            unchecked { ++i; }
        }
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}