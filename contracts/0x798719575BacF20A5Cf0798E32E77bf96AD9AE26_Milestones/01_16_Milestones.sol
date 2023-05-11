// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import { Pausable } from "../utils/Pausable.sol";
import { Ownable } from "../utils/Ownable.sol";

import { Stream } from "./../lib/Stream.sol";
import { IMilestones } from "./interfaces/IMilestones.sol";

/// @title Manager
/// @author Matthew Harrison
/// @notice A milestone based stream contract
contract Milestones is IMilestones, Stream {
    /// @notice The milestone payments array
    uint256[] internal msPayments;
    /// @notice The milestone dates array
    uint64[] internal msDates;
    /// @notice The current milestone incrementer
    uint48 internal currentMilestone;
    /// @notice The tip for the bot
    uint96 internal tip;

    constructor() initializer {}

    /// @notice Initialize the contract
    /// @param _owner The owner address of the contract
    /// @param _msPayments The payments for each milestone
    /// @param _msDates The dates for each milestone
    /// @param _tip The tip of the stream, paid to the bot
    /// @param _recipient The recipient address of the stream
    /// @param _token The token used for stream payments
    function initialize(
        address _owner,
        uint256[] calldata _msPayments,
        uint64[] calldata _msDates,
        uint96 _tip,
        address _recipient,
        address _token,
        address _botDAO
    ) external initializer {
        msPayments = _msPayments;
        msDates = _msDates;
        tip = _tip;
        recipient = _recipient;
        token = _token;
        botDAO = _botDAO;

        /// Grant initial ownership to a founder
        __Ownable_init(_owner);

        /// Pause the contract until the first auction
        __Pausable_init(false);
    }

    /// @notice Distribute payouts with tip calculation
    function release() external whenNotPaused returns (uint256) {
        uint256 _amount = _nextPayment();
        if (_amount == 0) return 0;

        uint256 amount = _amount - tip;
        _distribute(recipient, amount);
        _distribute(botDAO, tip);

        currentMilestone++;

        emit FundsDisbursed(address(this), _amount, "Milestones");

        return _amount;
    }

    /// @notice Release funds of a single stream with no tip payout
    /// @return The amount disbursed
    function claim() external whenNotPaused returns (uint256) {
        uint256 _amount = _nextPayment();
        if (_amount == 0) return 0;

        _distribute(recipient, _amount);

        currentMilestone++;

        emit FundsDisbursed(address(this), _amount, "Milestones");

        return _amount;
    }

    /// @notice Retrieve the current balance of a stream
    /// @return The balance of the stream
    function nextPayment() external view returns (uint256) {
        return _nextPayment();
    }

    /// @notice Get the current meta information about the stream
    /// @return currentMilestone The current milestone index
    /// @return currentPayment The current milestone payment
    /// @return currentDate The current milestone date
    /// @return tip The tip of the stream
    /// @return recipient The recipient address of the stream
    function getCurrentMilestone() external view returns (uint48, uint256, uint64, uint96, address) {
        if (msDates.length <= currentMilestone) {
            return (currentMilestone, 0, 0, tip, recipient);
        } else {
            return (currentMilestone, msPayments[currentMilestone], msDates[currentMilestone], tip, recipient);
        }
    }

    /// @notice Get the milestone payment and date via an index
    /// @param index The index of the milestone
    /// @return payment The milestone payment
    /// @return date The milestone date
    function getMilestone(uint88 index) external view returns (uint256, uint64) {
        return (msPayments[index], msDates[index]);
    }

    /// @notice Get the length of the milestones array
    /// @return milestonesAmount The length of the milestones array
    function getMilestoneLength() external view returns (uint256, uint256) {
        return (msPayments.length, msDates.length);
    }

    /// @notice Gets the next payment amount
    /// @return nextPaymentAmount The next payment amount
    function _nextPayment() internal view returns (uint256) {
        if (msDates.length <= currentMilestone) revert STREAM_FINISHED();
        if (block.timestamp < msDates[currentMilestone]) {
            return 0;
        }
        return msPayments[currentMilestone];
    }
}