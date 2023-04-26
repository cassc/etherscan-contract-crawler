// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./interfaces/IVesting.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Vesting contract.
 * @author Asymetrix Protocol Inc Team
 * @notice An implementation of a Vesting contract for ASX token distribution
 *         using vesting schedules.
 */
contract Vesting is Ownable, IVesting {
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(uint256 => VestingSchedule) private vestingSchedules;

    IERC20 private immutable token;

    uint256 private vestingSchedulesCount;

    uint256 private totalDistributionAmount;

    uint256 private totalReleasedAmount;

    /**
     * @notice Сonstructor of this Vesting contract.
     * @dev Sets ASX token contract address.
     * @param _token ASX token contract address.
     */
    constructor(address _token) {
        require(_token.isContract(), "Vesting: invalid ASX token address");

        token = IERC20(_token);
    }

    /**
     * @notice Returns the ASX token address.
     * @return The ASX token address.
     */
    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @notice Returns total vesting schedules count.
     * @return Total vesting schedules count.
     */
    function getVestingSchedulesCount() external view returns (uint256) {
        return vestingSchedulesCount;
    }

    /**
     * @notice Returns total distribution amount for all vesting schedules.
     * @return Total distribution amount for all vesting schedules.
     */
    function getTotalDistributionAmount() external view returns (uint256) {
        return totalDistributionAmount;
    }

    /**
     * @notice Returns total released amount for all vesting schedules.
     * @return Total released amount for all vesting schedules.
     */
    function getTotalReleasedAmount() external view returns (uint256) {
        return totalReleasedAmount;
    }

    /**
     * @notice Returns a vesting schedule by it's ID. If no vesting schedule
     *         exist with provided ID, returns an empty vesting schedule.
     * @param _vsid An ID of a vesting schedule.
     * @return A vesting schedule structure.
     */
    function getVestingSchedule(
        uint256 _vsid
    ) external view returns (VestingSchedule memory) {
        return vestingSchedules[_vsid];
    }

    /**
     * @notice Returns a list of vesting schedules paginated by their IDs.
     * @param _fromVsid An ID of a vesting schedule to start.
     * @param _toVsid An ID of a vesting schedule to finish.
     * @return A list with the found vesting schedule structures.
     */
    function getPaginatedVestingSchedules(
        uint256 _fromVsid,
        uint256 _toVsid
    ) external view returns (VestingSchedule[] memory) {
        require(_fromVsid <= _toVsid, "Vesting: invalid range");

        uint256 _dataSize = vestingSchedulesCount;

        require(_fromVsid < _dataSize, "Vesting: fromVsid out of bounds");
        require(_toVsid < _dataSize, "Vesting: toVsid out of bounds");

        VestingSchedule[] memory _schedules = new VestingSchedule[](
            _toVsid - _fromVsid + 1
        );

        for (uint256 i = _fromVsid; i <= _toVsid; i++) {
            _schedules[i - _fromVsid] = vestingSchedules[i];
        }

        return _schedules;
    }

    /**
     * @notice Returns releasable amount for a vesting schedule by provided ID.
     *         If no vesting schedule exist with provided ID, returns zero.
     * @param _vsid An ID of a vesting schedule.
     * @return A releasable amount.
     */
    function getReleasableAmount(
        uint256 _vsid
    ) external view returns (uint256) {
        return _computeReleasableAmount(vestingSchedules[_vsid]);
    }

    /**
     * @notice Creates a new vesting schedules in a batch by an owner.
     * @param _accounts An array of addresses of users for whom new vesting
     *                  schedules should be created.
     * @param _amounts An array of vesting schedules distribution amounts.
     * @param _lockPeriods An array of lock period durations (in seconds) that
     *                     should have place before distribution will start.
     * @param _releasePeriods An array of periods (in seconds) during wich ASX
     *                        tokens will be distributed after the lock period.
     */
    function createVestingSchedule(
        address[] memory _accounts,
        uint256[] memory _amounts,
        uint32[] memory _lockPeriods,
        uint32[] memory _releasePeriods
    ) external onlyOwner {
        require(
            _accounts.length > 0,
            "Vesting: accounts array length must be greater than 0"
        );
        require(
            _accounts.length == _amounts.length &&
                _accounts.length == _lockPeriods.length &&
                _accounts.length == _releasePeriods.length,
            "Vesting: lengths mismatch"
        );

        for (uint256 _i = 0; _i < _accounts.length; ++_i) {
            _createVestingSchedule(
                _accounts[_i],
                _amounts[_i],
                _lockPeriods[_i],
                _releasePeriods[_i]
            );
        }
    }

    /**
     * @notice Releases ASX tokens for a specified vesting schedule IDs in a
     *         batch.
     * @param _vsids An array of vesting schedule IDs.
     * @param _recipients An array of recipients of unlocked ASX tokens.
     */
    function release(
        uint256[] memory _vsids,
        address[] memory _recipients
    ) external {
        require(
            _vsids.length > 0,
            "Vesting: vesting schedules IDs array length must be greater than 0"
        );
        require(
            _vsids.length == _recipients.length,
            "Vesting: lengths mismatch"
        );

        for (uint256 _i = 0; _i < _vsids.length; ++_i) {
            _release(_vsids[_i], _recipients[_i]);
        }
    }

    /**
     * @notice Withdraws unused ASX tokens or othe tokens (including ETH) by an
     *         owner.
     * @param _token A token to withdraw. If equal to zero address - withdraws
     *               ETH.
     * @param _amount An amount of tokens for withdraw.
     * @param _recipient A recipient of withdrawn tokens.
     */
    function withdraw(
        address _token,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        require(_recipient != address(0), "Vesting: invalid recipient address");

        if (_token == address(0)) {
            payable(_recipient).transfer(_amount);
        } else if (_token != address(token)) {
            IERC20(_token).safeTransfer(_recipient, _amount);
        } else {
            require(
                getWithdrawableASXAmount() >= _amount,
                "Vesting: not enough unused ASX tokens"
            );

            token.safeTransfer(_recipient, _amount);
        }

        emit Withdrawn(_token, _recipient, _amount);
    }

    /**
     * @notice Returns an amount available for withdrawal (unused ASX tokens
     *         amount) by an owner.
     * @return A withdrawable amount.
     */
    function getWithdrawableASXAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - totalDistributionAmount;
    }

    /**
     * @notice Creates a new vesting schedule.
     * @param _account An address of a user for whom a new vesting schedule
     *                 should be created.
     * @param _amount Vesting schedule distribution amount.
     * @param _lockPeriod A lock period duration (in seconds) that should have
     *                    place before distribution will start.
     * @param _releasePeriod A period (in seconds) during wich ASX tokens will
     *                       be distributed after the lock period.
     */
    function _createVestingSchedule(
        address _account,
        uint256 _amount,
        uint32 _lockPeriod,
        uint32 _releasePeriod
    ) private {
        require(
            getWithdrawableASXAmount() >= _amount,
            "Vesting: not enough unused ASX tokens"
        );
        require(_account != address(0), "Vesting: invalid account address");
        require(
            _amount >= 1 ether,
            "Vesting: amount must be greater than or equal to 1"
        );
        require(_lockPeriod > 0, "Vesting: lock period must be greater than 0");
        require(
            _releasePeriod > 0,
            "Vesting: release period must be greater than 0"
        );

        uint256 _vsid = vestingSchedulesCount;

        vestingSchedules[_vsid] = VestingSchedule(
            _amount,
            0,
            _account,
            uint32(block.timestamp),
            _lockPeriod,
            _releasePeriod
        );

        ++vestingSchedulesCount;

        totalDistributionAmount += _amount;

        emit VestingScheduleCreated(vestingSchedules[_vsid]);
    }

    /**
     * @notice Releases ASX tokens for a specified vesting schedule ID.
     * @param _vsid A vesting schedule ID.
     * @param _recipient A recipient of unlocked ASX tokens.
     */
    function _release(uint256 _vsid, address _recipient) private {
        require(_recipient != address(0), "Vesting: invalid recipient address");

        VestingSchedule memory _vestingSchedule = vestingSchedules[_vsid];

        require(
            _vestingSchedule.startTimestamp != 0,
            "Vesting: vesting schedule does not exist"
        );
        require(
            _vestingSchedule.owner == msg.sender,
            "Vesting: caller is not an owner of a vesting schedule"
        );
        require(
            vestingSchedules[_vsid].released != vestingSchedules[_vsid].amount,
            "Vesting: vesting schedule is ended"
        );

        uint256 _amount = _computeReleasableAmount(_vestingSchedule);

        require(_amount > 0, "Vesting: nothing to release");

        vestingSchedules[_vsid].released += _amount;

        totalReleasedAmount += _amount;

        totalDistributionAmount -= _amount;

        token.safeTransfer(_recipient, _amount);

        emit Released(_vsid, _recipient, _amount);
    }

    /**
     * @notice A method for computing a releasable amount for a vesting
     *         schedule.
     * @param _vestingSchedule A vesting schedule for which to compute a
     *                         releasable amount.
     */
    function _computeReleasableAmount(
        VestingSchedule memory _vestingSchedule
    ) private view returns (uint256) {
        uint32 _currentTime = uint32(block.timestamp);
        uint32 _lockEndTime = _vestingSchedule.startTimestamp +
            _vestingSchedule.lockPeriod;

        if (
            (_currentTime < _lockEndTime) ||
            _vestingSchedule.released == _vestingSchedule.amount
        ) {
            return 0;
        } else {
            uint32 _secondsWithdraw = _currentTime - _lockEndTime;

            if (_secondsWithdraw >= _vestingSchedule.releasePeriod) {
                return _vestingSchedule.amount - _vestingSchedule.released;
            } else {
                return
                    _secondsWithdraw *
                    (_vestingSchedule.amount / _vestingSchedule.releasePeriod) -
                    _vestingSchedule.released;
            }
        }
    }
}