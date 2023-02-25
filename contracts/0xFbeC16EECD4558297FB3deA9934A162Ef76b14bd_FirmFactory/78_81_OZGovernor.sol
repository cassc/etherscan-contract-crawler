// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Governor, IGovernor, Context} from "openzeppelin/governance/Governor.sol";
import {GovernorSettings} from "openzeppelin/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "openzeppelin/governance/extensions/GovernorCountingSimple.sol";

import {GovernorCaptableVotes, ICaptableVotes} from "./lib/GovernorCaptableVotes.sol";
import {GovernorCaptableVotesQuorumFraction} from "./lib/GovernorCaptableVotesQuorumFraction.sol";

// Base contract which aggregates all the different OpenZeppelin Governor extensions
// and makes it possible to use behind a proxy instead of with a constructor
abstract contract OZGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorCaptableVotes,
    GovernorCaptableVotesQuorumFraction
{
    constructor() Governor(name()) GovernorSettings(1, 1, 1) {}

    function _setupGovernor(
        ICaptableVotes token_,
        uint256 quorumNumerator_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_
    ) internal {
        _setToken(token_);
        _updateQuorumNumerator(quorumNumerator_);
        _setVotingDelay(votingDelay_);
        _setVotingPeriod(votingPeriod_);
        _setProposalThreshold(proposalThreshold_);
    }

    function name() public pure override returns (string memory) {
        return "FirmVoting";
    }

    function quorumDenominator() public pure override returns (uint256) {
        return 10000;
    }

    // Reject receiving assets

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        // Reject receiving assets
        return bytes4(0);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        // Reject receiving assets
        return bytes4(0);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        // Reject receiving assets
        return bytes4(0);
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorCaptableVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }
}