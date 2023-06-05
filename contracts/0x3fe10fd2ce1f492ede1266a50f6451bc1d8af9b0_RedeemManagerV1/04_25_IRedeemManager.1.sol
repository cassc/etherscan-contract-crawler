//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../state/redeemManager/RedeemQueue.sol";
import "../state/redeemManager/WithdrawalStack.sol";

/// @title Redeem Manager Interface (v1)
/// @author Kiln
/// @notice This contract handles the redeem requests of all users
interface IRedeemManagerV1 {
    /// @notice Emitted when a redeem request is created
    /// @param owner The owner of the redeem request
    /// @param height The height of the redeem request in LsETH
    /// @param amount The amount of the redeem request in LsETH
    /// @param maxRedeemableEth The maximum amount of eth that can be redeemed from this request
    /// @param id The id of the new redeem request
    event RequestedRedeem(address indexed owner, uint256 height, uint256 amount, uint256 maxRedeemableEth, uint32 id);

    /// @notice Emitted when a withdrawal event is created
    /// @param height The height of the withdrawal event in LsETH
    /// @param amount The amount of the withdrawal event in LsETH
    /// @param ethAmount The amount of eth to distrubute to claimers
    /// @param id The id of the withdrawal event
    event ReportedWithdrawal(uint256 height, uint256 amount, uint256 ethAmount, uint32 id);

    /// @notice Emitted when a redeem request has been satisfied and filled (even partially) from a withdrawal event
    /// @param redeemRequestId The id of the redeem request
    /// @param withdrawalEventId The id of the withdrawal event used to fill the request
    /// @param lsEthAmountSatisfied The amount of LsETH filled
    /// @param ethAmountSatisfied The amount of ETH filled
    /// @param lsEthAmountRemaining The amount of LsETH remaining
    /// @param ethAmountExceeding The amount of eth added to the exceeding buffer
    event SatisfiedRedeemRequest(
        uint32 indexed redeemRequestId,
        uint32 indexed withdrawalEventId,
        uint256 lsEthAmountSatisfied,
        uint256 ethAmountSatisfied,
        uint256 lsEthAmountRemaining,
        uint256 ethAmountExceeding
    );

    /// @notice Emitted when a redeem request claim has been processed and matched at least once and funds are sent to the recipient
    /// @param redeemRequestId The id of the redeem request
    /// @param recipient The address receiving the redeem request funds
    /// @param ethAmount The amount of eth retrieved
    /// @param lsEthAmount The total amount of LsETH used to redeem the eth
    /// @param remainingLsEthAmount The amount of LsETH remaining
    event ClaimedRedeemRequest(
        uint32 indexed redeemRequestId,
        address indexed recipient,
        uint256 ethAmount,
        uint256 lsEthAmount,
        uint256 remainingLsEthAmount
    );

    /// @notice Emitted when the redeem demand is set
    /// @param oldRedeemDemand The old redeem demand
    /// @param newRedeemDemand The new redeem demand
    event SetRedeemDemand(uint256 oldRedeemDemand, uint256 newRedeemDemand);

    /// @notice Emitted when the River address is set
    /// @param river The new river address
    event SetRiver(address river);

    /// @notice Thrown When a zero value is provided
    error InvalidZeroAmount();

    /// @notice Thrown when a transfer error occured with LsETH
    error TransferError();

    /// @notice Thrown when the provided arrays don't have matching lengths
    error IncompatibleArrayLengths();

    /// @notice Thrown when the provided redeem request id is out of bounds
    /// @param id The redeem request id
    error RedeemRequestOutOfBounds(uint256 id);

    /// @notice Thrown when the withdrawal request id if out of bounds
    /// @param id The withdrawal event id
    error WithdrawalEventOutOfBounds(uint256 id);

    /// @notice Thrown when	the redeem request id is already claimed
    /// @param id The redeem request id
    error RedeemRequestAlreadyClaimed(uint256 id);

    /// @notice Thrown when the redeem request and withdrawal event are not matching during claim
    /// @param redeemRequestId The provided redeem request id
    /// @param withdrawalEventId The provided associated withdrawal event id
    error DoesNotMatch(uint256 redeemRequestId, uint256 withdrawalEventId);

    /// @notice Thrown when the provided withdrawal event exceeds the redeem demand
    /// @param withdrawalAmount The amount of the withdrawal event
    /// @param redeemDemand The current redeem demand
    error WithdrawalExceedsRedeemDemand(uint256 withdrawalAmount, uint256 redeemDemand);

    /// @notice Thrown when the payment after a claim failed
    /// @param recipient The recipient of the payment
    /// @param rdata The revert data
    error ClaimRedeemFailed(address recipient, bytes rdata);

    /// @param _river The address of the River contract
    function initializeRedeemManagerV1(address _river) external;

    /// @notice Retrieve the global count of redeem requests
    function getRedeemRequestCount() external view returns (uint256);

    /// @notice Retrieve the details of a specific redeem request
    /// @param _redeemRequestId The id of the request
    /// @return The redeem request details
    function getRedeemRequestDetails(uint32 _redeemRequestId)
        external
        view
        returns (RedeemQueue.RedeemRequest memory);

    /// @notice Retrieve the global count of withdrawal events
    function getWithdrawalEventCount() external view returns (uint256);

    /// @notice Retrieve the details of a specific withdrawal event
    /// @param _withdrawalEventId The id of the withdrawal event
    /// @return The withdrawal event details
    function getWithdrawalEventDetails(uint32 _withdrawalEventId)
        external
        view
        returns (WithdrawalStack.WithdrawalEvent memory);

    /// @notice Retrieve the amount of redeemed LsETH pending to be supplied with withdrawn ETH
    /// @return The amount of eth in the buffer
    function getBufferedExceedingEth() external view returns (uint256);

    /// @notice Retrieve the amount of LsETH waiting to be exited
    /// @return The amount of LsETH waiting to be exited
    function getRedeemDemand() external view returns (uint256);

    /// @notice Resolves the provided list of redeem request ids
    /// @dev The result is an array of equal length with ids or error code
    /// @dev -1 means that the request is not satisfied yet
    /// @dev -2 means that the request is out of bounds
    /// @dev -3 means that the request has already been claimed
    /// @dev This call was created to be called by an off-chain interface, the output could then be used to perform the claimRewards call in a regular transaction
    /// @param _redeemRequestIds The list of redeem requests to resolve
    /// @return withdrawalEventIds The list of withdrawal events matching every redeem request (or error codes)
    function resolveRedeemRequests(uint32[] calldata _redeemRequestIds)
        external
        view
        returns (int64[] memory withdrawalEventIds);

    /// @notice Creates a redeem request
    /// @param _lsETHAmount The amount of LsETH to redeem
    /// @param _recipient The recipient owning the redeem request
    /// @return redeemRequestId The id of the redeem request
    function requestRedeem(uint256 _lsETHAmount, address _recipient) external returns (uint32 redeemRequestId);

    /// @notice Creates a redeem request using msg.sender as recipient
    /// @param _lsETHAmount The amount of LsETH to redeem
    /// @return redeemRequestId The id of the redeem request
    function requestRedeem(uint256 _lsETHAmount) external returns (uint32 redeemRequestId);

    /// @notice Claims the rewards of the provided redeem request ids
    /// @param _redeemRequestIds The list of redeem requests to claim
    /// @param _withdrawalEventIds The list of withdrawal events to use for every redeem request claim
    /// @param _skipAlreadyClaimed True if the call should not revert on claiming of already claimed requests
    /// @param _depth The maximum recursive depth for the resolution of the redeem requests
    /// @return claimStatuses The list of claim statuses. 0 for fully claimed, 1 for partially claimed, 2 for skipped
    function claimRedeemRequests(
        uint32[] calldata _redeemRequestIds,
        uint32[] calldata _withdrawalEventIds,
        bool _skipAlreadyClaimed,
        uint16 _depth
    ) external returns (uint8[] memory claimStatuses);

    /// @notice Claims the rewards of the provided redeem request ids
    /// @param _redeemRequestIds The list of redeem requests to claim
    /// @param _withdrawalEventIds The list of withdrawal events to use for every redeem request claim
    /// @return claimStatuses The list of claim statuses. 0 for fully claimed, 1 for partially claimed, 2 for skipped
    function claimRedeemRequests(uint32[] calldata _redeemRequestIds, uint32[] calldata _withdrawalEventIds)
        external
        returns (uint8[] memory claimStatuses);

    /// @notice Reports a withdraw event from River
    /// @param _lsETHWithdrawable The amount of LsETH that can be redeemed due to this new withdraw event
    function reportWithdraw(uint256 _lsETHWithdrawable) external payable;

    /// @notice Pulls exceeding buffer eth
    /// @param _max The maximum amount that should be pulled
    function pullExceedingEth(uint256 _max) external;
}