// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Common {
    /**
     * @param identifier  bytes32  Identifier of the distribution
     * @param token       address  Address of the token to distribute
     * @param merkleRoot  bytes32  Merkle root of the distribution
     * @param proof       bytes32  Proof of the distribution
     */
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }

    /**
     * @param proposal          bytes32  Proposal to bribe
     * @param token             address  Token to bribe with
     * @param briber            address  Address of the briber
     * @param amount            uint256  Amount of tokens to bribe with
     * @param maxTokensPerVote  uint256  Maximum amount of tokens to use per vote
     * @param periods           uint256  Number of periods to bribe for
     * @param periodDuration    uint256  Duration of each period
     * @param proposalDeadline  uint256  Deadline for the proposal
     * @param permitDeadline    uint256  Deadline for the permit2 signature
     * @param signature         bytes    Permit2 signature
     */
    struct DepositBribeParams {
        bytes32 proposal;
        address token;
        address briber;
        uint256 amount;
        uint256 maxTokensPerVote;
        uint256 periods;
        uint256 periodDuration;
        uint256 proposalDeadline;
        uint256 permitDeadline;
        bytes signature;
    }

    /**
     * @param rwIdentifier      bytes32    Identifier for claiming reward
     * @param fromToken         address    Address of token to swap from
     * @param toToken           address    Address of token to swap to
     * @param fromAmount        uint256    Amount of fromToken to swap
     * @param toAmount          uint256    Amount of toToken to receive
     * @param deadline          uint256    Timestamp until which swap may be fulfilled
     * @param callees           address[]  Array of addresses to call (DEX addresses)
     * @param callLengths       uint256[]  Index of the beginning of each call in exchangeData
     * @param values            uint256[]  Array of encoded values for each call in exchangeData
     * @param exchangeData      bytes      Calldata to execute on callees
     * @param rwMerkleProof     bytes32[]  Merkle proof for the reward claim
     */
    struct ClaimAndSwapData {
        bytes32 rwIdentifier;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 deadline;
        address[] callees;
        uint256[] callLengths;
        uint256[] values;
        bytes exchangeData;
        bytes32[] rwMerkleProof;
    }

    /**
     * @param identifier   bytes32    Identifier for claiming reward
     * @param account      address    Address of the account to claim for
     * @param amount       uint256    Amount of tokens to claim
     * @param merkleProof  bytes32[]  Merkle proof for the reward claim
     */
    struct Claim {
        bytes32 identifier;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }
}