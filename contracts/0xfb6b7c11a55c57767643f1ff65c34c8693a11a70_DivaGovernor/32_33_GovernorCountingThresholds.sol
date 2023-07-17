// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/governance/Governor.sol";
/**
 * @dev Custom error for invalid configuration of thresholds
 */
error DaoInvalidThresholdTypeConfiguration();

/**
 * @title GovernorCountingThresholds extension
 * @author ShamirLabs
 * @dev Extension of {Governor} for simple, 3 options, vote counting. Three different thresholds
 * for a proposal to be successful can be configured:
 * - DEFAULT: 50% + 1
 * - MODERATE: 66% + 1
 * - LARGE: 75% + 1
 */
abstract contract GovernorCountingThresholds is Governor {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    /**
     * @dev three thresholds types
     */
    enum ThresholdType {
        DEFAULT,
        MODERATE,
        LARGE
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
        ThresholdType successThreshold; // @dev store proposal threshold at proposition time
    }

    /**
     * @dev emitted when a proposal success threshold is set
     */
    event SuccessThresholdTypeSet(uint256 proposalId, ThresholdType threshold);

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev threshold thresholds per target per function
     */
    mapping(bytes4 => ThresholdType) private _targetFunctionThreshold;

    /**
     * @notice GovernorCountingThresholds Constructor
     * @param functionSignatures list of function signatures
     * @param functionsThresholds list of ThresholdType
     */
    constructor(
        bytes4[] memory functionSignatures,
        ThresholdType[] memory functionsThresholds
    ) {
        if (functionSignatures.length != functionsThresholds.length)
            revert DaoInvalidThresholdTypeConfiguration();

        for (uint256 i = 0; i < functionSignatures.length; i++) {
            _targetFunctionThreshold[
                functionSignatures[i]
            ] = functionsThresholds[i];
        }
    }

    /**
     * @notice This function is used to add threshold configuration to functions
     * @param signaturesLargeThreshold list of function signatures that should have a large threshold
     * @param signaturesModerateThreshold list of function signatures that should have a moderate threshold
     * @param signaturesDefaultThreshold list of function signatures that should have a default threshold
     */
    function addThresholdConfiguration(
        bytes4[] memory signaturesLargeThreshold,
        bytes4[] memory signaturesModerateThreshold,
        bytes4[] memory signaturesDefaultThreshold
    ) external onlyGovernance {
        for (uint256 i = 0; i < signaturesLargeThreshold.length; i++) {
            _targetFunctionThreshold[
                signaturesLargeThreshold[i]
            ] = ThresholdType.LARGE;
        }

        for (uint256 i = 0; i < signaturesModerateThreshold.length; i++) {
            _targetFunctionThreshold[
                signaturesModerateThreshold[i]
            ] = ThresholdType.MODERATE;
        }

        for (uint256 i = 0; i < signaturesDefaultThreshold.length; i++) {
            _targetFunctionThreshold[
                signaturesDefaultThreshold[i]
            ] = ThresholdType.DEFAULT;
        }
    }

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE()
        public
        pure
        virtual
        override
        returns (string memory)
    {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(
        uint256 proposalId,
        address account
    ) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(
        uint256 proposalId
    )
        public
        view
        virtual
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (
            proposalVote.againstVotes,
            proposalVote.forVotes,
            proposalVote.abstainVotes
        );
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(
        uint256 proposalId
    ) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return
            quorum(proposalSnapshot(proposalId)) <=
            proposalVote.forVotes + proposalVote.abstainVotes;
    }

    /**
     * @notice Returns the threshold type for a given function signature
     * @param proposalId function signature
     */
    function getSuccessThreshold(
        uint256 proposalId
    ) public view virtual returns (ThresholdType) {
        return _proposalVotes[proposalId].successThreshold;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     * @param proposalId id of the proposal
     */
    function _voteSucceeded(
        uint256 proposalId
    ) internal view virtual override returns (bool) {
        bool result;
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        ThresholdType threshold = _proposalVotes[proposalId].successThreshold;

        // @dev edge cases for againsVotes and forVotes
        if (threshold == ThresholdType.LARGE) {
            // @dev LARGE threshold is a super majority of 75% |||   FOR / (FOR + AGAINST)) > 3/4 ->  4 * FOR > 3 * (FOR + AGAINST) ->  FOR > 3 * TOTAL
            result = (proposalVote.forVotes > 3 * proposalVote.againstVotes);
        } else if (threshold == ThresholdType.MODERATE) {
            // @dev MODERATE threshold is a super majority of 66% FOR / (FOR + AGAINST)) > 2/3 ->  3 * FOR > 2 * (FOR + AGAINST) ->  FOR > 2 * AGAINST
            result = (proposalVote.forVotes > 2 * proposalVote.againstVotes);
        } else {
            // @dev DEFAULT threshold is a super majority of 50% FOR / (FOR + AGAINST)) > 1/2 -> 2 * FOR > 1 * (FOR + AGAINST)
            result = (proposalVote.forVotes > proposalVote.againstVotes);
        }

        return result;
    }

    /**
     * @notice Returns true if the proposal has succeeded
     */
    function voteSucceeded(
        uint256 proposalId
    ) public view virtual returns (bool) {
        return _voteSucceeded(proposalId);
    }

    /**
     * @notice This function is used at the proposal creation time to set the success threshold based on the function
     * signatures of the actions
     */
    function _setSuccessThreshold(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) internal {
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        // @dev start with default threshold
        ThresholdType threshold = ThresholdType.DEFAULT;

        // @dev increase it if any of the targets has a function with a higher threshold
        for (uint256 i = 0; i < calldatas.length; i++) {
            bytes4 sig = bytes4(calldatas[i]);

            if (_targetFunctionThreshold[sig] == ThresholdType.LARGE) {
                threshold = ThresholdType.LARGE;
                break;
            }

            if (_targetFunctionThreshold[sig] == ThresholdType.MODERATE) {
                threshold = ThresholdType.MODERATE;
            }
        }

        _proposalVotes[proposalId].successThreshold = threshold;
        emit SuccessThresholdTypeSet(proposalId, threshold);
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(
            !proposalVote.hasVoted[account],
            "GovernorVotingSimple: vote already cast"
        );
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}