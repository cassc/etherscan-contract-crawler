// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRule {
    /**
     * @notice A custom rule that validates that the voter can cast a vote or propose a proposal
     * @param governor The address of the GovernorBravo contract
     * @param voter The final delegatee that's casting the vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain, 0xff=propose
     * @return IRule.validate.selector
     */
    function validate(
        address governor,
        address voter,
        uint256 proposalId,
        uint8 support
    ) external view returns (bytes4);
}