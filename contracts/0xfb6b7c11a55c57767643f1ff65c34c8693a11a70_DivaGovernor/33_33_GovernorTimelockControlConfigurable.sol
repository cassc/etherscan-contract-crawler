// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/governance/extensions/IGovernorTimelock.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "./DivaTimelockController.sol";

/**
 * @dev Custom error for invalid configuration of delays
 */
error DaoInvalidDelaysConfiguration();

/**
 * @dev Custom error for invalid configuration of delays
 */
error DaoInvalidDelaysSetup();

/**
 * @dev Custom error for invalid configuration of delays
 */
error CancelProposalMustHaveShortDelay();

/**
 * @dev Custom error for invalid configuration of delays
 */
error InvalidDelayValue();

/**
 * @dev Custom error for short delay proposal with value
 */
error ShortDelayProposalCannotHaveValue();

/**
 * @title GovernorTimelockControlConfigurable extension
 * @author ShamirLabs
 * @dev Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a custom
 * delay based on function signature in actions, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (and ideally the executor) roles for the {Governor} to work properly.
 */
abstract contract GovernorTimelockControlConfigurable is
    IGovernorTimelock,
    Governor
{
    DivaTimelockController private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;
    mapping(bytes4 => DelayType) private _functionsDelays;
    uint256 private _defaultDelay;
    uint256 private _shortDelay;
    uint256 private _longDelay;

    uint256 private constant SECONDS_PER_BLOCK = 12;

    bytes4 public constant CANCEL_PROPOSAL_TYPEHASH =
        bytes4(keccak256(bytes("cancel(bytes32)")));

    enum DelayType {
        // we do not need it here but we keep it at the first slot so when
        // _functionsDelays is queried, if an entry does not exist in the mapping (and returns 0)
        // will be the same than setting it to DEFAULT
        DEFAULT,
        // short delay type is used for emergency proposals
        // in order for a proposal to have a SHORT delay, all functions calls must have the SHORT delay type
        // This is to avoid having a malicious proposal bypass the timelock by including just a pause function after
        // the malicious operation
        SHORT,
        // long delay type is used to operations like recovering funds from the pool
        // as long as 1 function call belongs to this type, the whole proposal will have a LONG delay
        // This is to avoid a malicious DAO to include any actions PLUS recovering funds from the pool
        // and bypass the long timelock to give users time to recover their positions
        LONG
    }

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock and configure timelocks for function signatures
     *
     */
    constructor(
        DivaTimelockController timelockAddress,
        bytes4[] memory functionSignatures,
        DelayType[] memory functionsDelays,
        uint256 defaultDelay,
        uint256 shortDelay,
        uint256 longDelay
    ) {
        // @dev enforce proper configuration in deployment
        if (shortDelay >= defaultDelay || longDelay <= defaultDelay) {
            revert DaoInvalidDelaysSetup();
        }

        _defaultDelay = defaultDelay;
        _shortDelay = shortDelay;
        _longDelay = longDelay;

        if (functionSignatures.length != functionsDelays.length) {
            revert DaoInvalidDelaysConfiguration();
        }

        for (uint256 i = 0; i < functionSignatures.length; i++) {
            _functionsDelays[functionSignatures[i]] = functionsDelays[i];
        }

        _updateTimelock(timelockAddress);
    }

    /**
     * @notice This function is used to add a delay configuration for function signatures
     * @param signaturesLongDelay function signatures to be set with a long delay
     * @param signaturesShortDelay function signatures to be set with a short delay
     * @param signaturesDefaultDelay function signatures to be set with a default delay
     */
    function addDelayConfiguration(
        bytes4[] memory signaturesLongDelay,
        bytes4[] memory signaturesShortDelay,
        bytes4[] memory signaturesDefaultDelay
    ) external onlyGovernance {
        for (uint256 i = 0; i < signaturesLongDelay.length; i++) {
            if (signaturesLongDelay[i] == CANCEL_PROPOSAL_TYPEHASH)
                revert CancelProposalMustHaveShortDelay();

            _functionsDelays[signaturesLongDelay[i]] = DelayType.LONG;
        }
        for (uint256 i = 0; i < signaturesShortDelay.length; i++) {
            _functionsDelays[signaturesShortDelay[i]] = DelayType.SHORT;
        }
        for (uint256 i = 0; i < signaturesDefaultDelay.length; i++) {
            if (signaturesDefaultDelay[i] == CANCEL_PROPOSAL_TYPEHASH)
                revert CancelProposalMustHaveShortDelay();
            _functionsDelays[signaturesDefaultDelay[i]] = DelayType.DEFAULT;
        }
    }

    /**
     * @notice This function is used to update the short delay value
     * @param newDelay new delay to be set
     */
    function updateShortDelay(uint256 newDelay) external onlyGovernance {
        if (newDelay >= _defaultDelay) revert InvalidDelayValue();

        _shortDelay = newDelay;
    }

    /**
     * @notice This function is used to update the default delay value
     * @param newDelay new delay to be set
     */
    function updateDefaultDelay(uint256 newDelay) external onlyGovernance {
        if (_shortDelay >= newDelay || newDelay >= _longDelay)
            revert InvalidDelayValue();

        _defaultDelay = newDelay;
    }

    /**
     * @notice This function is used to update the long delay value
     * @param newDelay new delay to be set
     */
    function updateLongDelay(uint256 newDelay) external onlyGovernance {
        if (newDelay <= _defaultDelay) revert InvalidDelayValue();

        _longDelay = newDelay;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, Governor) returns (bool) {
        return
            interfaceId == type(IGovernorTimelock).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overridden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(
        uint256 proposalId
    )
        public
        view
        virtual
        override(IGovernor, Governor)
        returns (ProposalState)
    {
        ProposalState status = super.state(proposalId);
        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else if (_timelock.isOperationPending(queueid)) {
            return ProposalState.Queued;
        } else {
            return ProposalState.Canceled;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(
        uint256 proposalId
    ) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            descriptionHash
        );
        require(
            state(proposalId) == ProposalState.Succeeded,
            "Governor: proposal not successful"
        );

        uint256 delay = _getDelay(calldatas, values);
        _timelockIds[proposalId] = _timelock.hashOperationBatch(
            targets,
            values,
            calldatas,
            0,
            descriptionHash
        );

        _timelock.scheduleBatch(
            targets,
            values,
            calldatas,
            0,
            descriptionHash,
            delay
        );

        emit ProposalQueued(proposalId, block.timestamp + delay);
        return proposalId;
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled, and executed through governance proposals.
     *
     * CAUTION: It is not recommended to change the timelock while there are other queued governance proposals.
     */
    function updateTimelock(
        DivaTimelockController newTimelock
    ) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(DivaTimelockController newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }

    /**
     * @dev Function used to calculate the timelock delay based on the actions the proposal is trying to eventually execute
     * If there is ONE function with DelayType == LONG delay, we return _longDelay
     * If ALL functions have DelayType == SHORT, we return _shortDelay
     * Otherwise, we return _defaultDelay
     */
    function _getDelay(
        bytes[] memory calldatas,
        uint256[] memory values
    ) internal view returns (uint256) {
        // if there are no functions to execute in a proposal, it won't use the SHORT delay
        // it will also NOT enter the loop, which means the DEFAULT delay will be used
        bool isShortDelay = calldatas.length > 0;
        for (uint256 i = 0; i < calldatas.length; i++) {
            bytes4 sig = bytes4(calldatas[i]);

            // @dev any proposal that attempts to withdraw ETH uses long delay
            if (values[i] > 0) {
                return _longDelay * SECONDS_PER_BLOCK;
            }

            DelayType delay = _functionsDelays[sig];
            if (delay == DelayType.LONG) {
                return _longDelay * SECONDS_PER_BLOCK;
            }
            if (delay != DelayType.SHORT) {
                isShortDelay = false;
            }
        }
        return
            isShortDelay == true
                ? _shortDelay * SECONDS_PER_BLOCK
                : _defaultDelay * SECONDS_PER_BLOCK;
    }

    /**
     * @dev Overridden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256 /* proposalId */,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(
            targets,
            values,
            calldatas,
            0,
            descriptionHash
        );
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }
}