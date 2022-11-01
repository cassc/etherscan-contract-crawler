// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for Kapital DAO Voting Weight Sources
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice The governance contract is responsible for interpreting the meaning
 * of the reported voting weight, based on the voting weight source address.
 * The voting weight could be in units of KAP tokens, but could alternatively
 * be in different units such as LP tokens.
 */
interface IVotingWeightSource {
    function votingWeight(address voter) external view returns (uint256);
}