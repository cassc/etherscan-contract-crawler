pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/VestingFrequencyHelper.sol";
import "./VestingScheduleLogic.sol";

abstract contract VestingScheduleBase is VestingScheduleLogic {
    mapping (address => mapping(VestingFrequencyHelper.Frequency => VestingData[])) public vestingSchedule;
    mapping (address => bool) internal _isWhiteListVesting;

    function _getVestingSchedules(address user, VestingFrequencyHelper.Frequency freq) internal override view returns (VestingData[] memory) {
        return vestingSchedule[user][freq];
    }

    function _removeFirstSchedule(address user, VestingFrequencyHelper.Frequency freq) internal override {
        _popFirstSchedule(vestingSchedule[user][freq]);
    }

    function _lockVestingSchedule(address _to, VestingFrequencyHelper.Frequency _freq, uint256 _amount) internal override {
        vestingSchedule[_to][_freq].push(_newVestingData(_amount, _freq));
    }

    // use for mocking test
    function _setVestingTime(address user, uint8 freq, uint256 index, uint256 timestamp) internal {
        vestingSchedule[user][VestingFrequencyHelper.Frequency(freq)][index].vestingTime = uint64(timestamp);
    }

    function _setWhitelistVesting(address user, bool val) internal {
        _isWhiteListVesting[user] = val;
        emit WhiteListVestingChanged(user, val);
    }

    function _isWhitelistVesting(address user) internal view returns (bool) {
        return _isWhiteListVesting[user];
    }
}