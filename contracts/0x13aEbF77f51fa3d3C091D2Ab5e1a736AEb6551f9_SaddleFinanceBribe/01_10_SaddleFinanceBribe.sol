// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BribeBase} from "./BribeBase.sol";

contract SaddleFinanceBribe is BribeBase {
    event SetProposalChoices(
        uint256 indexed proposalIndex,
        uint256 choiceCount,
        uint256 deadline
    );

    constructor(address _BRIBE_VAULT) BribeBase(_BRIBE_VAULT, "SADDLE_FINANCE") {}

    /**
        @notice Set proposals based on the index of the proposal and the number of choices
        @param  proposalIndex   uint256  Proposal index
        @param  choiceCount     uint256  Number of choices to be voted for
        @param  deadline        uint256  Proposal deadline
     */
    function setProposalChoices(
        uint256 proposalIndex,
        uint256 choiceCount,
        uint256 deadline
    ) external onlyAuthorized {
        require(choiceCount != 0, "Invalid number of choices");

        for (uint256 i; i < choiceCount; ++i) {
            // The final proposalId is built from encoding both the index and the choice index
            _setProposal(
                keccak256(abi.encodePacked(proposalIndex, i)),
                deadline
            );
        }

        emit SetProposalChoices(proposalIndex, choiceCount, deadline);
    }
}