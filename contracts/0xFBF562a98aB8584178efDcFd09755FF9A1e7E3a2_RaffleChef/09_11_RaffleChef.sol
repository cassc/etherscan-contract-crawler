// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TypeAndVersion} from "./interfaces/TypeAndVersion.sol";
import {IRaffleChef} from "./interfaces/IRaffleChef.sol";
import {FeistelShuffle} from "./vendor/FeistelShuffle.sol";
import {Withdrawable} from "./vendor/Withdrawable.sol";

/// @title RaffleChef
/// @author kevincharm
/// @notice RaffleChef is the master of raffles. He can make raffles and he is a fair guy.
///     RaffleChef does NOT record whether a winner has claimed their win; this is upto an
///     external raffle consumer to handle. Take care not to double-spend a raffle, unless
///     that is your intent.
contract RaffleChef is IRaffleChef, TypeAndVersion, Ownable, Withdrawable {
    /// @notice ID of next created raffle
    uint256 public nextRaffleId;

    /// @dev Mapping of raffleId => Raffle data
    mapping(uint256 => Raffle) private raffles;

    /// @dev RESERVED
    uint256[48] private __RaffleChef_gap;

    constructor(uint256 startingRaffleId) Ownable() {
        if (startingRaffleId == 0) {
            revert StartingRaffleIdTooLow(startingRaffleId);
        }
        nextRaffleId = startingRaffleId;
    }

    /// @notice See {TypeAndVersion-typeAndVersion}
    function typeAndVersion() external pure override returns (string memory) {
        return "RaffleChef 1.0.0";
    }

    function _authoriseWithdrawal() internal virtual override onlyOwner {}

    /// @notice Get an existing raffle
    /// @param raffleId ID of raffle to get
    /// @return raffle data, if it exists
    function getRaffle(uint256 raffleId) public view returns (Raffle memory) {
        return raffles[raffleId];
    }

    /// @notice Get the current state of raffle, given a `raffleId`
    /// @param raffleId ID of raffle to get
    /// @return See {IRaffleChef-RaffleState} enum
    function getRaffleState(
        uint256 raffleId
    ) public view returns (RaffleState) {
        Raffle memory raffle = getRaffle(raffleId);
        if (
            raffle.participantsMerkleRoot != bytes32(0) &&
            raffle.nWinners > 0 &&
            raffle.randomSeed != 0 &&
            bytes(raffle.provenance).length > 0
        ) {
            return RaffleState.Committed;
        } else {
            return RaffleState.Unknown;
        }
    }

    /// @notice See {IRaffleChef-commit}
    function commit(
        bytes32 participantsMerkleRoot,
        uint256 nParticipants,
        uint256 nWinners,
        string calldata provenance,
        uint256 randomness
    ) external returns (uint256) {
        uint256 raffleId = nextRaffleId;
        nextRaffleId += 1;

        // NB: Validity of provenance is not actually checked
        if (
            participantsMerkleRoot == 0 ||
            nParticipants == 0 ||
            nWinners > nParticipants ||
            randomness == 0 ||
            bytes(provenance).length == 0
        ) {
            revert InvalidCommitment(
                raffleId,
                participantsMerkleRoot,
                nParticipants,
                nWinners,
                randomness,
                provenance
            );
        }

        Raffle memory raffle = Raffle({
            participantsMerkleRoot: participantsMerkleRoot,
            nParticipants: nParticipants,
            nWinners: nWinners,
            randomSeed: randomness,
            owner: msg.sender,
            provenance: provenance
        });
        raffles[raffleId] = raffle;

        emit RaffleCommitted(raffleId);

        return raffleId;
    }

    /// @notice See {IRaffleChef-verifyRaffleWinner}
    function verifyRaffleWinner(
        uint256 raffleId,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 merkleIndex
    ) external view returns (bool isWinner, uint256 permutedIndex) {
        Raffle memory raffle = raffles[raffleId];
        if (raffle.randomSeed == 0) {
            revert RaffleNotRolled(raffleId);
        }

        // Verify that the merkle proof is correct.
        // This proves that `account` is a member of the participants list,
        // at the given `index` (as derived from the merkle proof's path indices).
        bool isValidProof = verifyMerkleProof(
            raffle.participantsMerkleRoot,
            leafHash,
            proof,
            merkleIndex
        );
        if (!isValidProof) {
            revert InvalidProof(leafHash, proof);
        }

        // Compute the shuffled index using the random seed using a stateless shuffle
        // that bijectively maps P -> P' where P is the participants list, and P' is
        // a permutation of P.
        permutedIndex = FeistelShuffle.getPermutedIndex(
            merkleIndex,
            raffle.nParticipants,
            raffle.randomSeed,
            4
        );

        // A winner is defined as any account having an original index that maps to a
        // shuffled index that is less than the total number of winners.
        isWinner = permutedIndex < raffle.nWinners;

        return (isWinner, permutedIndex);
    }

    /// @notice Verify a merkle proof given a merkle root.
    /// @param merkleRoot Root of the merkle tree to verify against
    /// @param leafHash Hash of leaf element
    /// @param proof Hashes of leaf siblings required to construct the root
    /// @param index leaf index in merkle tree
    /// @return isValid true if proof is valid for supplied leaf
    function verifyMerkleProof(
        bytes32 merkleRoot,
        bytes32 leafHash,
        bytes32[] calldata proof,
        uint256 index
    ) internal pure returns (bool isValid) {
        bytes32 computedHash = leafHash;
        for (uint256 i = 0; i < proof.length; ++i) {
            computedHash = hashMerklePair(
                computedHash,
                proof[i],
                (index >> i) & 1 == 1
            );
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == merkleRoot;
    }

    /// @notice Hash a merkle pair -> keccak256(left,right)
    /// @param a left value
    /// @param b right value
    /// @param reverse if true, reverses the order of left and right
    /// @return h Hash of merkle pair, constructing a parent node
    function hashMerklePair(
        bytes32 a,
        bytes32 b,
        bool reverse
    ) internal pure returns (bytes32 h) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Use scratch space [0, 0x40)
            // h <- keccak256(reverse ? b : a, reverse ? a : b)
            let rev := and(reverse, 0x1)
            mstore(mul(rev, 0x20), a)
            mstore(mul(iszero(rev), 0x20), b)
            h := keccak256(0, 0x40)
        }
    }
}