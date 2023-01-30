// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {mul} from "fiat/core/utils/Math.sol";
import {Guarded} from "fiat/core/utils/Guarded.sol";

import {IOptimisticOracle} from "./interfaces/IOptimisticOracle.sol";

/// @title OptimisticOracle
/// @notice The Optimistic Oracle allows for gas-efficient oracle value updates.
/// Bonded proposers can optimistically propose a value for a given RateId which can be disputed within a set time
/// interval by computing the value on-chain. Proposers are not rewarded for doing so directly and instead are only
/// compensated in the event that they call the `dispute` function, as `dispute` is a gas intensive operation due to its
/// computation of the expected value on-chain. Compensation is sourced from the bond put up by the malicious proposer.
/// This is an abstract contract which provides the base logic for shifting and disputing proposals and bond management.
abstract contract OptimisticOracle is IOptimisticOracle, Guarded {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error OptimisticOracle__activateRateId_activeRateId(bytes32 rateId);
    error OptimisticOracle__deactivateRateId_inactiveRateId(bytes32 rateId);
    error OptimisticOracle__shift_invalidPreviousProposal();
    error OptimisticOracle__shift_unbondedProposer();
    error OptimisticOracle__dispute_inactiveRateId();
    error OptimisticOracle__dispute_invalidDispute();
    error OptimisticOracle__settleDispute_unknownProposal();
    error OptimisticOracle__settleDispute_alreadyDisputed();
    error OptimisticOracle__bond_bondedProposer(bytes32 rateId);
    error OptimisticOracle__bond_inactiveRateId(bytes32 rateId);
    error OptimisticOracle__unbond_unbondedProposer();
    error OptimisticOracle__unbond_invalidProposal();
    error OptimisticOracle__unbond_isProposing();
    error OptimisticOracle__recover_unbondedProposer();
    error OptimisticOracle__recover_notLocked();

    /// @notice Address of the target where values should be pushed to
    address public immutable target;
    /// @notice Address of the bonded token
    IERC20 public immutable bondToken;
    /// @notice Amount of `bondToken` proposers have to bond for each "rate feed" [precision of bondToken]
    uint256 public immutable bondSize;
    /// @notice Oracle type (metadata)
    bytes32 public immutable oracleType;
    /// @notice Time until a proposed value can not be disputed anymore
    uint256 public immutable disputeWindow;

    /// @notice Map of ProposalIds by RateId
    /// For each "rate feed" (id. by RateId) only the current proposal is stored.
    /// Instead of storing all the data associated with a proposal, only the keccak256 hash of the data
    /// is stored as the ProposalId. The ProposalId is derived via `computeProposalId`.
    /// @dev RateId => ProposalId
    mapping(bytes32 => bytes32) public proposals;

    /// @notice Map of active RateIds
    /// A `rateId` has to be activated in order for proposer to deposit a bond for it and dispute proposals which
    /// reference the `rateId`.
    /// @dev RateId => bool
    mapping(bytes32 => bool) public activeRateIds;

    /// @notice Mapping of Bonds
    /// The Optimistic Oracle needs to ensure that there's a bond attached to every proposal made which can be claimed
    /// if the proposal is incorrect. In practice this requires that:
    /// - a proposer can't reuse their bond for multiple proposals (for the same or different rateIds)
    /// - a proposer can't unbond a proposal which hasn't passed `disputeWindow`
    /// For each "rate feed" (id. by RateId) it is required that a proposer submit proposals with a bond of `bondSize`.
    /// @dev Proposer => RateId => bonded
    mapping(address => mapping(bytes32 => bool)) public bonds;

    /// @param target_ Address of target
    /// @param oracleType_ Unique identifier
    /// @param bondToken_ Address of the ERC20 token used for bonding proposers
    /// @param bondSize_ Amount of `bondToken` a proposer has to bond in order to submit proposals for each `rateId`
    /// @param disputeWindow_ Protocol specific period until a proposed value can not be disputed [seconds//blocks]
    constructor(
        address target_,
        bytes32 oracleType_,
        IERC20 bondToken_,
        uint256 bondSize_,
        uint256 disputeWindow_
    ) {
        target = target_;
        bondToken = bondToken_;
        bondSize = bondSize_;
        oracleType = oracleType_;
        disputeWindow = disputeWindow_;
    }

    /// ======== Rate Configuration ======== ///

    /// @notice Activates proposing for a given `rateId` and creates the initial / blank proposal for it.
    /// @dev Sender has to be allowed to call this method. Reverts if the `rateId` is already active.
    /// @param rateId RateId
    function activateRateId(bytes32 rateId) public checkCaller {
        if (activeRateIds[rateId])
            revert OptimisticOracle__activateRateId_activeRateId(rateId);

        activeRateIds[rateId] = true;

        // update target and set the current proposal as a blank (initial) proposal
        push(rateId);
    }

    /// @notice Deactivates proposing for a given `rateId` and removes the last proposal which references it.
    /// @dev Sender has to be allowed to call this method. Reverts if the `rateId` is already inactive.
    /// @param rateId RateId
    function deactivateRateId(bytes32 rateId) public checkCaller {
        if (!activeRateIds[rateId]) {
            revert OptimisticOracle__deactivateRateId_inactiveRateId(rateId);
        }

        delete activeRateIds[rateId];

        // clear the current proposal to stop bonded proposers to `shift` new values for this rateId
        // without a valid current proposal, no new shifts can be made
        delete proposals[rateId];
    }

    /// ======== Proposal Management ======== ///

    /// @notice Queues a new proposed `value` for a given `rateId` and pushes `prevValue` to target
    /// @dev Can only be called by a bonded proposer. Reverts if either:
    /// - the specified previous proposal (`prevProposer`, `prevValue`, `prevNonce`) is invalid / non existent,
    /// - `disputeWindow` still active,
    /// - current proposed value is disputable (`dispute` has to be called beforehand)
    /// For the initial shift for a given `rateId` - `prevProposer`, `prevValue` and `prevNonce` are set to 0.
    /// @param rateId RateId for which to shift the proposals
    /// @param prevProposer Address of the previous proposer
    /// @param prevValue Value of the previous proposal
    /// @param prevNonce Nonce of the previous proposal
    /// @param value Value of the new proposal [wad]
    /// @param data Data of the new proposal
    function shift(
        bytes32 rateId,
        address prevProposer,
        uint256 prevValue,
        bytes32 prevNonce,
        uint256 value,
        bytes memory data
    ) external override(IOptimisticOracle) {
        // check that proposer is bonded for the given `rateId`
        if (!isBonded(msg.sender, rateId))
            revert OptimisticOracle__shift_unbondedProposer();

        // verify that the previous proposal exists
        if (
            proposals[rateId] !=
            computeProposalId(rateId, prevProposer, prevValue, prevNonce)
        ) {
            revert OptimisticOracle__shift_invalidPreviousProposal();
        }

        // derive the nonce of the new proposal from `data` (reverts if prev. proposal is within the `disputeWindow`)
        bytes32 nonce = encodeNonce(prevNonce, data);

        // push the previous value to target
        // skip if `prevNonce` is 0 (blank (initial) proposal) since it is not an actual proposal
        if (prevNonce != 0 && prevValue != 0) _push(rateId, prevValue);

        // update the proposal with the new values
        proposals[rateId] = computeProposalId(rateId, msg.sender, value, nonce);

        emit Propose(rateId, nonce);
    }

    /// @notice Disputes a proposed value by fetching the correct value from the implementation's data feed.
    /// The bond of the proposer of the disputed value is sent to the `receiver`.
    /// @param rateId RateId of the proposal being disputed
    /// @param proposer Address of the proposer of the proposal being disputed
    /// @param receiver Address of the receiver of the `proposer`'s bond
    /// @param value_ Value of the proposal being disputed [wad]
    /// @param nonce Nonce of the proposal being disputed
    /// @param data Additional encoded data required for disputes
    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value_,
        bytes32 nonce,
        bytes memory data
    ) external override(IOptimisticOracle) {
        if (!activeRateIds[rateId])
            revert OptimisticOracle__dispute_inactiveRateId();

        // validate the proposed value
        (uint256 result, uint256 validValue, bytes memory validData) = validate(
            value_,
            rateId,
            nonce,
            data
        );

        // if result is zero then the validation was successful
        if (result == 0) revert OptimisticOracle__dispute_invalidDispute();

        emit Validate(rateId, proposer, result);

        // skip the dispute window check when replacing the invalid nonce
        bytes32 validNonce = encodeNonce(bytes32(0), validData);

        _settleDispute(
            rateId,
            proposer,
            receiver,
            value_,
            nonce,
            validValue,
            validNonce
        );

        emit Propose(rateId, validNonce);
    }

    /// @notice Validates `proposedValue` for a given `nonce`
    /// @param proposedValue Value to be validated [wad]
    /// @param rateId RateId
    /// @param nonce Protocol specific nonce of the `proposedValue`
    /// @param data Protocol specific data buffer corresponding to `proposedValue`
    /// @return result 0 for success, otherwise a protocol specific validation failure code is returned
    /// @return validValue Value that was computed onchain
    /// @return validData Data corresponding to `validValue`
    function validate(
        uint256 proposedValue,
        bytes32 rateId,
        bytes32 nonce,
        bytes memory data
    )
        public
        virtual
        override(IOptimisticOracle)
        returns (
            uint256 result,
            uint256 validValue,
            bytes memory validData
        );

    /// @notice Settles the dispute by overwriting the invalid proposal with a new proposal
    /// and claims the malicious proposer's bond
    /// @param rateId RateId of the proposal to dispute
    /// @param proposer Address of the proposer of the disputed proposal
    /// @param receiver Address of the bond receiver
    /// @param value Value of the proposal to dispute [wad]
    /// @param nonce Nonce of the proposal to dispute
    /// @param validValue Value computed by the validator [wad]
    /// @param validNonce Nonce computed by the validator
    function _settleDispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        bytes32 nonce,
        uint256 validValue,
        bytes32 validNonce
    ) internal {
        if (proposer == address(this)) {
            revert OptimisticOracle__settleDispute_alreadyDisputed();
        }

        // verify the proposal data
        if (
            proposals[rateId] !=
            computeProposalId(rateId, proposer, value, nonce)
        ) {
            revert OptimisticOracle__settleDispute_unknownProposal();
        }

        // overwrite the proposal with the value computed by the Validator
        proposals[rateId] = computeProposalId(
            rateId,
            address(this),
            validValue,
            validNonce
        );

        // block the proposer from further bonding
        _blockCaller(bytes4(keccak256("bond(bytes32[])")), proposer);

        // transfer the bond to the receiver (disregard the outcome)
        _claimBond(proposer, rateId, receiver);

        emit Dispute(rateId, proposer, msg.sender, value, validValue);
    }

    /// @notice Pushes a value directly to target by computing it on-chain
    /// without going through the shift / dispute process
    /// @dev Overwrites the current queued proposal with the blank (initial) proposal
    /// @param rateId RateId
    function push(bytes32 rateId) public virtual override(IOptimisticOracle);

    /// @notice Pushes a proposed value to target
    /// @param rateId RateId
    /// @param value Value that will be pushed to target [wad]
    function _push(bytes32 rateId, uint256 value) internal virtual;

    /// @notice Computes the ProposalId
    /// @param rateId RateId
    /// @param proposer Address of the proposer
    /// @param value Proposed value [wad]
    /// @param nonce Nonce of the proposal
    /// @return proposalId Computed proposalId
    function computeProposalId(
        bytes32 rateId,
        address proposer,
        uint256 value,
        bytes32 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(rateId, proposer, value, nonce));
    }

    /// @notice Derive the nonce of a proposal from `prevNonce` and `data`.
    /// @dev Must revert if the `disputeWindow` is still active
    /// @param prevNonce Nonce of the previous proposal
    /// @param data Data of the current proposal
    /// @return nonce of the current proposal
    function encodeNonce(bytes32 prevNonce, bytes memory data)
        public
        view
        virtual
        override(IOptimisticOracle)
        returns (bytes32);

    /// @notice Decode the data hash and the `proposeTimestamp` from a proposal `nonce`
    /// @dev Reverts if the `disputeWindow` is still active
    /// @param nonce Protocol specific nonce containing `proposeTimestamp`
    /// @return dataHash Pre-image of `nonce`
    /// @return proposeTimestamp Timestamp at which the proposal was made [uint64]
    function decodeNonce(bytes32 nonce)
        public
        view
        virtual
        override(IOptimisticOracle)
        returns (bytes32 dataHash, uint64 proposeTimestamp);

    /// @notice Checks that the dispute operation can be performed by the OptimisticOracle given `nonce`
    /// @return canDispute True if dispute operation can be performed
    function canDispute(bytes32 nonce)
        public
        view
        virtual
        override(IOptimisticOracle)
        returns (bool);

    /// ======== Bond Management ======== ///

    /// @notice Deposits `bondToken`'s for the specified `rateIds`
    /// The total bonded amount is `rateIds.length * bondSize`
    /// The caller needs to be whitelisted by the oracle owner
    /// @dev Reverts if the caller already deposited a bond for a given `rateId`
    /// Requires the caller to set an allowance for this contract
    /// @param rateIds List of `rateId`'s for each which sender wants to submit proposals for
    function bond(bytes32[] calldata rateIds)
        public
        override(IOptimisticOracle)
        checkCaller
    {
        _bond(msg.sender, rateIds);
    }

    /// @notice Deposits `bondToken`'s for a given `proposer` for the specified `rateIds`.
    /// The total bonded amount is `rateIds.length * bondSize`.
    /// @dev Requires the caller to set an allowance for this contract.
    /// Reverts if `proposer` already deposited a bond for a given `rateId`.
    /// @param proposer Address of the proposer
    /// @param rateIds List of `rateId`'s for each which `proposer` wants to submit proposals for
    function bond(address proposer, bytes32[] calldata rateIds)
        public
        override(IOptimisticOracle)
        checkCaller
    {
        _bond(proposer, rateIds);
    }

    /// @notice Deposits `bondToken`'s for a given `proposer` for the specified `rateIds`.
    /// The total bonded amount is `rateIds.length * bondSize`.
    /// @dev Requires the caller to set an allowance for this contract.
    /// Reverts if `proposer` already deposited a bond for a given `rateId`.
    /// @param proposer Address of the proposer
    /// @param rateIds List of `rateId`'s for each which `proposer` wants to submit proposals for
    function _bond(address proposer, bytes32[] calldata rateIds) private {
        // transfer the total amount to bond from the caller
        bondToken.safeTransferFrom(
            msg.sender,
            address(this),
            mul(rateIds.length, bondSize)
        );

        // mark the `proposer` as bonded for each rateId
        for (uint256 i = 0; i < rateIds.length; ++i) {
            bytes32 rateId = rateIds[i];

            // `rateId` needs to be active
            if (!activeRateIds[rateId]) {
                revert OptimisticOracle__bond_inactiveRateId(rateId);
            }

            // `proposer` should be unbonded for the specified `rateId`'s
            if (isBonded(proposer, rateId)) {
                revert OptimisticOracle__bond_bondedProposer(rateId);
            }

            bonds[proposer][rateId] = true;
        }

        emit Bond(proposer, rateIds);
    }

    /// @notice Unbond the caller for a given `rateId` and send the bonded amount to `receiver`
    /// Proposers can retrieve their bond if either:
    /// - the last proposal was made by another proposer,
    /// - `disputeWindow` for the last proposal has elapsed,
    /// - `rateId` is inactive
    /// @dev Reverts if the caller is not bonded for a given `rateId`
    /// @param rateId RateId for which to unbond
    /// @param lastProposerForRateId Address of the last proposer for `rateId`
    /// @param value Value of the current proposal made for `rateId`
    /// @param nonce Nonce of the current proposal made for `rateId`
    /// @param receiver Address of the recipient of the bonded amount
    function unbond(
        bytes32 rateId,
        address lastProposerForRateId,
        uint256 value,
        bytes32 nonce,
        address receiver
    ) public override(IOptimisticOracle) {
        bytes32 proposalId = computeProposalId(
            rateId,
            lastProposerForRateId,
            value,
            nonce
        );

        // revert if `proposalId` is invalid
        if (proposals[rateId] != proposalId)
            revert OptimisticOracle__unbond_invalidProposal();

        // revert if the `proposer` is `msg.sender` and the dispute window is active
        // skipping and allowing unbond if the rate is removed is intended
        if (
            lastProposerForRateId == msg.sender &&
            activeRateIds[rateId] &&
            canDispute(nonce)
        ) {
            revert OptimisticOracle__unbond_isProposing();
        }

        // revert if `msg.sender` is not bonded
        if (!isBonded(msg.sender, rateId))
            revert OptimisticOracle__unbond_unbondedProposer();

        delete bonds[msg.sender][rateId];
        bondToken.safeTransfer(receiver, bondSize);

        emit Unbond(msg.sender, rateId, receiver);
    }

    /// @notice Claims the bond of `proposer` for `rateId` and sends the bonded amount (`bondSize`) of `bondToken`
    /// to `receiver`
    /// @dev Does not revert if the `proposer` is unbonded for a given `rateId` to avoid deadlocks
    /// @param proposer Address of the proposer from which to claim the bond
    /// @param rateId RateId for which the proposer bonded
    /// @param receiver Address of the recipient of the claimed bond
    function _claimBond(
        address proposer,
        bytes32 rateId,
        address receiver
    ) internal returns (bool) {
        if (!isBonded(proposer, rateId)) return false;

        // clear bond
        delete bonds[proposer][rateId];

        // avoids blocking the dispute in case the transfer fails
        try bondToken.transfer(receiver, bondSize) {} catch {}

        emit ClaimBond(proposer, rateId, receiver);

        return true;
    }

    /// @notice Checks that `proposer` is bonded for a given `rateId`
    /// @param proposer Address of the proposer
    /// @param rateId RateId
    /// @return isBonded True if `proposer` is bonded
    function isBonded(address proposer, bytes32 rateId)
        public
        view
        override(IOptimisticOracle)
        returns (bool)
    {
        return bonds[proposer][rateId];
    }

    /// @notice Allow `proposer` to call `bond`
    /// @dev Sender has to be allowed to call this method
    /// @param proposer Address of the proposer
    function allowProposer(address proposer)
        external
        override(IOptimisticOracle)
        checkCaller
    {
        _allowCaller(bytes4(keccak256("bond(bytes32[])")), proposer);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks `shift`, `dispute` operations for a given set of `rateId`s.
    /// @dev Sender has to be allowed to call this method. Reverts if the rate was already unregistered.
    /// @param rateIds RateIds for which to lock `shift` and `dispute`
    function lock(bytes32[] calldata rateIds)
        public
        override(IOptimisticOracle)
        checkCaller
    {
        uint256 length = rateIds.length;
        for (uint256 rateIdx = 0; rateIdx < length; ) {
            deactivateRateId(rateIds[rateIdx]);
            unchecked {
                ++rateIdx;
            }
        }

        emit Lock();
    }

    /// @notice Allows proposers to withdraw their bond for a given `rateId` in case after the oracle is locked
    /// @param rateId RateId for which the proposer wants to withdraw the bond
    /// @param receiver Address that will receive the bond
    function recover(bytes32 rateId, address receiver)
        public
        override(IOptimisticOracle)
    {
        if (activeRateIds[rateId]) {
            revert OptimisticOracle__recover_notLocked();
        }

        // transfer and clear the bond
        if (!_claimBond(msg.sender, rateId, receiver)) {
            revert OptimisticOracle__recover_unbondedProposer();
        }
    }
}