// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AxiomV1Access} from "./AxiomV1Access.sol";
import {IAxiomV1} from "./interfaces/IAxiomV1.sol";
import {MerkleTree} from "./libraries/MerkleTree.sol";
import {MerkleMountainRange} from "./libraries/MerkleMountainRange.sol";
import "./libraries/configuration/AxiomV1Configuration.sol";

/// @title  Axiom V1 Core
/// @notice Core Axiom smart contract that verifies the validity of historical block hashes using SNARKs.
/// @dev    For use in a UUPS upgradeable contract.
contract AxiomV1Core is IAxiomV1, AxiomV1Access {
    using {MerkleTree.merkleRoot} for bytes32[HISTORICAL_NUM_ROOTS];
    using MerkleMountainRange for MerkleMountainRange.MMR;

    address public verifierAddress;
    address public historicalVerifierAddress;

    mapping(uint32 => bytes32) public historicalRoots;
    MerkleMountainRange.MMR public historicalMMR;
    bytes32[MMR_RING_BUFFER_SIZE] public mmrRingBuffer;

    error SNARKVerificationFailed();
    error AxiomBlockVerificationFailed();
    error UpdatingIncorrectNumberOfBlocks();
    error StartingBlockNotMultipleOfBatchSize();
    error NotRecentEndBlock();
    error BlockHashIncorrect();
    error MerkleProofFailed();

    /// @notice Initializes the contract and the parent contracts.
    function __AxiomV1Core_init(
        address _verifierAddress,
        address _historicalVerifierAddress,
        address guardian,
        address prover
    ) internal onlyInitializing {
        __AxiomV1Access_init();
        __AxiomV1Core_init_unchained(_verifierAddress, _historicalVerifierAddress, guardian, prover);
    }

    /// @notice Initializes the contract without calling parent contract initializers.
    function __AxiomV1Core_init_unchained(
        address _verifierAddress,
        address _historicalVerifierAddress,
        address guardian,
        address prover
    ) internal onlyInitializing {
        require(_verifierAddress != address(0)); // AxiomV1Core: _verifierAddress cannot be the zero address
        require(_historicalVerifierAddress != address(0)); // AxiomV1Core: _historicalVerifierAddress cannot be the zero address"
        require(guardian != address(0)); // AxiomV1Core: guardian cannot be the zero address
        require(prover != address(0)); // AxiomV1Core: prover cannot be the zero address

        _grantRole(PROVER_ROLE, prover);
        _grantRole(GUARDIAN_ROLE, guardian);

        verifierAddress = _verifierAddress;
        historicalVerifierAddress = _historicalVerifierAddress;
        emit UpgradeSnarkVerifier(_verifierAddress);
        emit UpgradeHistoricalSnarkVerifier(_historicalVerifierAddress);
    }

    function updateRecent(bytes calldata proofData) external onlyProver {
        requireNotFrozen();
        (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root) =
            getBoundaryBlockData(proofData);
        // See `getBoundaryBlockData` comments for initial `proofData` formatting

        uint32 numFinal = endBlockNumber - startBlockNumber + 1;
        if (numFinal > BLOCK_BATCH_SIZE) revert UpdatingIncorrectNumberOfBlocks();
        if (startBlockNumber % BLOCK_BATCH_SIZE != 0) revert StartingBlockNotMultipleOfBatchSize();
        if (endBlockNumber >= block.number) revert NotRecentEndBlock();
        if (block.number - endBlockNumber > 256) revert NotRecentEndBlock();
        if (blockhash(endBlockNumber) != endHash) revert BlockHashIncorrect();

        if (!_verifyRaw(proofData)) {
            revert SNARKVerificationFailed();
        }

        if (root == bytes32(0)) {
            // We have a Merkle mountain range of max depth 10 (so length 11 total) ordered in **decreasing** order of peak size, so:
            // `root` (above) is the peak for depth 10
            // `roots` below are the peaks for depths 9..0 where `roots[i]` is for depth `9 - i`
            // 384 + 32 * 7 + 32 * 2 * i .. 384 + 32 * 7 + 32 * 2 * (i + 1): `roots[i]` (32 bytes) as two uint128 cast to uint256, same as blockHash
            // Note that the decreasing ordering is *different* than the convention in library MerkleMountainRange

            // compute Merkle root of completed Merkle mountain range with 0s for unconfirmed blockhashes
            for (uint256 round = 0; round < BLOCK_BATCH_DEPTH; round++) {
                bytes32 peak = getAuxMmrPeak(proofData, BLOCK_BATCH_DEPTH - 1 - round);
                if (peak != 0) {
                    root = keccak256(abi.encodePacked(peak, root));
                } else {
                    root = keccak256(abi.encodePacked(root, MerkleTree.getEmptyHash(round)));
                }
            }
        } else {
            // this indicates numFinal = BLOCK_BATCH_SIZE and root is the Merkle root of blockhashes for blocks [startBlockNumber, startBlockNumber + BLOCK_BATCH_SIZE)
            if (historicalMMR.len == (startBlockNumber >> BLOCK_BATCH_DEPTH)) {
                // the historicalMMR holds a commitment to blocks [0, startBlockNumber), so we can now extend it by 1024 blocks
                // we copy to memory as a gas optimization because we need to compute the commitment to store in the ring buffer
                MerkleMountainRange.MMR memory mmr = historicalMMR.clone();
                uint32 peaksChanged = mmr.appendSingle(root);
                mmr.index = (mmr.index + 1) % MMR_RING_BUFFER_SIZE;
                mmrRingBuffer[mmr.index] = mmr.commit();
                historicalMMR.copyFrom(mmr, peaksChanged);

                emit MerkleMountainRangeEvent(mmr.len, mmr.index);
            }
        }
        historicalRoots[startBlockNumber] = keccak256(abi.encodePacked(prevHash, root, numFinal));
        emit UpdateEvent(startBlockNumber, prevHash, root, numFinal);
    }

    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external onlyProver {
        requireNotFrozen();
        (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root) =
            getBoundaryBlockData(proofData);

        if (startBlockNumber % BLOCK_BATCH_SIZE != 0) revert StartingBlockNotMultipleOfBatchSize();
        if (endBlockNumber - startBlockNumber != BLOCK_BATCH_SIZE - 1) {
            revert UpdatingIncorrectNumberOfBlocks();
        }
        if (historicalRoots[endBlockNumber + 1] != keccak256(abi.encodePacked(endHash, nextRoot, nextNumFinal))) {
            revert BlockHashIncorrect();
        }

        if (!_verifyRaw(proofData)) {
            revert SNARKVerificationFailed();
        }

        historicalRoots[startBlockNumber] = keccak256(abi.encodePacked(prevHash, root, BLOCK_BATCH_SIZE));
        emit UpdateEvent(startBlockNumber, prevHash, root, BLOCK_BATCH_SIZE);
    }

    /// @dev endHashProofs is length HISTORICAL_NUM_ROOTS - 1 because the last endHash is provided in proofData
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[HISTORICAL_NUM_ROOTS] calldata roots,
        bytes32[BLOCK_BATCH_DEPTH + 1][HISTORICAL_NUM_ROOTS - 1] calldata endHashProofs,
        bytes calldata proofData
    ) external onlyProver {
        requireNotFrozen();
        (bytes32 _prevHash, bytes32 _endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 aggregateRoot) =
            getBoundaryBlockData(proofData);

        if (startBlockNumber % BLOCK_BATCH_SIZE != 0) revert StartingBlockNotMultipleOfBatchSize();
        if (endBlockNumber - startBlockNumber != HISTORICAL_BLOCK_BATCH_SIZE - 1) {
            revert UpdatingIncorrectNumberOfBlocks();
        }
        if (historicalRoots[endBlockNumber + 1] != keccak256(abi.encodePacked(_endHash, nextRoot, nextNumFinal))) {
            revert BlockHashIncorrect();
        }
        if (roots.merkleRoot() != aggregateRoot) {
            revert MerkleProofFailed();
        }

        if (!_verifyHistoricalRaw(proofData)) {
            revert SNARKVerificationFailed();
        }

        for (uint256 i = 0; i < HISTORICAL_NUM_ROOTS; i++) {
            if (i != HISTORICAL_NUM_ROOTS - 1) {
                bytes32 proofCheck = endHashProofs[i][BLOCK_BATCH_DEPTH];
                for (uint256 j = 0; j < BLOCK_BATCH_DEPTH; j++) {
                    proofCheck = keccak256(abi.encodePacked(endHashProofs[i][BLOCK_BATCH_DEPTH - 1 - j], proofCheck));
                }
                if (proofCheck != roots[i]) revert MerkleProofFailed();
            }
            bytes32 prevHash = i == 0 ? _prevHash : endHashProofs[i - 1][BLOCK_BATCH_DEPTH];
            uint32 start = uint32(startBlockNumber + i * BLOCK_BATCH_SIZE);
            historicalRoots[start] = keccak256(abi.encodePacked(prevHash, roots[i], BLOCK_BATCH_SIZE));
            emit UpdateEvent(start, prevHash, roots[i], BLOCK_BATCH_SIZE);
        }
    }

    function appendHistoricalMMR(uint32 startBlockNumber, bytes32[] calldata roots, bytes32[] calldata prevHashes)
        external
    {
        requireNotFrozen();
        if (roots.length == 0) revert(); // must append non-empty list
        if (roots.length != prevHashes.length) revert(); // roots and prevHashes must be same length
        if (startBlockNumber != historicalMMR.len * BLOCK_BATCH_SIZE) revert(); // startBlockNumber must be historicalMMR.len * BLOCK_BATCH_SIZE

        MerkleMountainRange.MMR memory mmr = historicalMMR.clone();
        for (uint256 i = 0; i < roots.length; i++) {
            // roots[i] = (prevHash, root)
            bytes32 commitment = keccak256(abi.encodePacked(prevHashes[i], roots[i], BLOCK_BATCH_SIZE));
            if (historicalRoots[startBlockNumber] != commitment) revert AxiomBlockVerificationFailed();
            startBlockNumber += BLOCK_BATCH_SIZE;
        }
        uint32 peaksChanged = mmr.append(roots);
        mmr.index = (mmr.index + 1) % MMR_RING_BUFFER_SIZE;
        mmrRingBuffer[mmr.index] = mmr.commit();
        historicalMMR.copyFrom(mmr, peaksChanged);

        emit MerkleMountainRangeEvent(mmr.len, mmr.index);
    }

    /// @notice Updates the address of the SNARK verifier contract, governed by a 'timelock'.
    ///         To avoid timelock bypass by metamorphic contracts, users should verify that
    ///         the contract deployed at `_verifierAddress` does not contain any `SELFDESTRUCT`
    ///         or `DELEGATECALL` opcodes.
    function upgradeSnarkVerifier(address _verifierAddress) external onlyRole(TIMELOCK_ROLE) {
        verifierAddress = _verifierAddress;
        emit UpgradeSnarkVerifier(_verifierAddress);
    }

    /// @notice Updates the address of the historical SNARK verifier contract, governed by a 'timelock'.
    ///         To avoid timelock bypass by metamorphic contracts, users should verify that
    ///         the contract deployed at `_historicalVerifierAddress` does not contain any `SELFDESTRUCT`
    ///         or `DELEGATECALL` opcodes.    
    /// @dev    We expect this should never need to be called since the historical verifier is only used for the initial batch import of historical block hashes.
    function upgradeHistoricalSnarkVerifier(address _historicalVerifierAddress) external onlyRole(TIMELOCK_ROLE) {
        historicalVerifierAddress = _historicalVerifierAddress;
        emit UpgradeHistoricalSnarkVerifier(_historicalVerifierAddress);
    }

    function historicalMMRPeaks(uint32 i) external view returns (bytes32) {
        return historicalMMR.peaks[i];
    }

    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) public view returns (bool) {
        bytes32 blockHash = blockhash(blockNumber);
        if (blockHash == 0x0) revert(); // Must supply block hash of one of 256 most recent blocks
        return (blockHash == claimedBlockHash);
    }

    function isBlockHashValid(BlockHashWitness calldata witness) public view returns (bool) {
        if (witness.claimedBlockHash == 0x0) revert(); // Claimed block hash cannot be 0
        uint32 side = witness.blockNumber % BLOCK_BATCH_SIZE;
        uint32 startBlockNumber = witness.blockNumber - side;
        bytes32 merkleRoot = historicalRoots[startBlockNumber];
        if (merkleRoot == 0) revert(); // Merkle root must be stored already
        // compute Merkle root of blockhash
        bytes32 root = witness.claimedBlockHash;
        for (uint256 i = 0; i < BLOCK_BATCH_DEPTH; i++) {
            // depth = BLOCK_BATCH_DEPTH - i
            // 0 for left, 1 for right
            if ((side >> i) & 1 == 0) {
                root = keccak256(abi.encodePacked(root, witness.merkleProof[i]));
            } else {
                root = keccak256(abi.encodePacked(witness.merkleProof[i], root));
            }
        }
        return (merkleRoot == keccak256(abi.encodePacked(witness.prevHash, root, witness.numFinal)));
    }

    function mmrVerifyBlockHash(
        bytes32[] calldata mmr,
        uint8 bufferId,
        uint32 blockNumber,
        bytes32 claimedBlockHash,
        bytes32[] calldata merkleProof
    ) public view {
        if (keccak256(abi.encodePacked(mmr)) != mmrRingBuffer[bufferId]) {
            revert AxiomBlockVerificationFailed();
        }
        // mmr.length <= 32
        uint32 peakId = uint32(mmr.length - 1);
        uint32 side = blockNumber;
        while ((BLOCK_BATCH_SIZE << peakId) <= side) {
            if (peakId == 0) revert(); // blockNumber outside of range of MMR
            peakId--;
            side -= BLOCK_BATCH_SIZE << peakId;
        }
        // merkleProof is a merkle proof of claimedBlockHash into the tree with root mmr[peakId]
        require(merkleProof.length == BLOCK_BATCH_DEPTH + peakId);
        bytes32 root = claimedBlockHash;
        for (uint256 i = 0; i < merkleProof.length; i++) {
            // 0 for left, 1 for right
            if ((side >> i) & 1 == 0) {
                root = keccak256(abi.encodePacked(root, merkleProof[i]));
            } else {
                root = keccak256(abi.encodePacked(merkleProof[i], root));
            }
        }
        if (root != mmr[peakId]) {
            revert AxiomBlockVerificationFailed();
        }
    }

    function _verifyRaw(bytes calldata input) private returns (bool) {
        (bool success,) = verifierAddress.call(input);
        return success;
    }

    function _verifyHistoricalRaw(bytes calldata input) private returns (bool) {
        (bool success,) = historicalVerifierAddress.call(input);
        return success;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}