// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { Pausable } from "../utils/Pausable.sol";
import { Ownable } from "../utils/Ownable.sol";

import { UUPS } from "../proxy/UUPS.sol";

import { Stream } from "./../lib/Stream.sol";
import { IIntervals } from "./interfaces/IIntervals.sol";

/// @title Intervals
/// @author Matthew Harrison
/// @notice The contract for all streams with intervals
contract Intervals is IIntervals, Stream {
    /// @notice The start date of the stream
    uint64 internal startDate;
    /// @notice The end date of the stream
    uint64 internal endDate;
    /// @notice The interval of the stream
    uint32 internal interval;
    /// @notice The tip of the stream, paid to the bot
    uint96 internal tip;
    /// @notice A timestamp of when last payment was made
    uint256 internal lastTimePaid;
    /// @notice The amount owed to the recipient
    uint256 internal owed;

    constructor() initializer {}

    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _startDate The start date of the stream
    /// @param _endDate The end date of the stream
    /// @param _interval The interval of the stream
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _owed The amount owed to the recipient
    /// @param _recipient The recipient address of the stream
    /// @param _token The token address of the stream
    function initialize(
        address _owner,
        uint64 _startDate,
        uint64 _endDate,
        uint32 _interval,
        uint96 _tip,
        uint256 _owed,
        address _recipient,
        address _token,
        address _botDAO
    ) external initializer {
        if (startDate > endDate) revert INCORRECT_DATE_RANGE();

        lastTimePaid = _startDate;
        startDate = _startDate;
        endDate = _endDate;
        interval = _interval;
        tip = _tip;
        owed = _owed;
        recipient = _recipient;
        token = _token;
        botDAO = _botDAO;

        /// Grant initial ownership to a founder
        __Ownable_init(_owner);

        /// Pause the contract until the first auction
        __Pausable_init(false);
    }

    /// @notice Distribute payout
    /// @return amount The amount disbursed
    function release() external whenNotPaused returns (uint256) {
        if (startDate > block.timestamp) revert STREAM_HASNT_STARTED();
        (uint256 _amount, uint256 multiplier) = _nextPayment();
        if (_amount == 0) return 0;
        uint256 amount = _amount - tip;
        _distribute(recipient, amount);
        _distribute(botDAO, tip);

        lastTimePaid = lastTimePaid + (interval * multiplier);

        emit FundsDisbursed(address(this), amount, "Intervals");

        return _amount;
    }

    /// @notice Release funds of a single stream with no tip payout
    function claim() external whenNotPaused returns (uint256) {
        if (startDate > block.timestamp) revert STREAM_HASNT_STARTED();
        (uint256 _amount, uint256 multiplier) = _nextPayment();
        if (_amount == 0) return 0;

        _distribute(recipient, _amount);

        lastTimePaid = lastTimePaid + (interval * multiplier);

        emit FundsDisbursed(address(this), _amount, "Intervals");

        return _amount;
    }

    /// @notice Retrieve the current balance of a stream
    /// @return nextPaymentAmount The next payment amount
    function nextPayment() external view returns (uint256) {
        (uint256 _amount, ) = _nextPayment();
        return _amount;
    }

    /// @notice Get stream details
    /// @return startDate The start date of the stream
    /// @return endDate The end date of the stream
    /// @return interval The interval of the stream
    /// @return tip The tip of the stream, paid to the bot
    /// @return owed The amount owed to the recipient
    /// @return lastTimePaid A timestamp of when last payment was made
    /// @return recipient The recipient address of the stream
    function getCurrentInterval() external view returns (uint64, uint64, uint32, uint96, uint256, uint256, address) {
        return (startDate, endDate, interval, tip, owed, lastTimePaid, recipient);
    }

    /// @notice Gets balance of stream
    /// @return nextPaymentAmount The next payment amount
    function _nextPayment() internal view returns (uint256, uint256) {
        unchecked {
            if (lastTimePaid >= endDate) revert STREAM_FINISHED();

            uint256 elapsed = block.timestamp - lastTimePaid;
            if (elapsed > (endDate - lastTimePaid)) elapsed = endDate - lastTimePaid;

            if ((endDate - lastTimePaid) < interval) revert STREAM_FINISHED();
            if (elapsed < interval) return (0, 0);

            uint256 multiplier = elapsed / interval;
            return (owed * multiplier, multiplier);
        }
    }
}