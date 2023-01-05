/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/CoreTypes.sol";
import "./lib/MerkleTree.sol";
import "./interfaces/IBlockHistory.sol";
import "./interfaces/IRecursiveVerifier.sol";

import {
    RecursiveProof,
    SignedRecursiveProof,
    getProofSigner,
    readHashWords
} from "./lib/Proofs.sol";

/**
 * @title BlockHistory
 * @author Theori, Inc.
 * @notice BlockHistory allows trustless and cheap verification of any
 *         historical block hash. Historical blocks are divided into chunks of
 *         fixed size, and each chunk's merkle root is stored on-chain. The
 *         merkle roots are validated on chain using aggregated SNARK proofs,
 *         enabling both trustlessness and scalability.
 *
 * @dev Each SNARK proof validates some contiguous block headers and has
 *      public inputs (parentHash, lastHash, merkleRoot). Here the merkleRoot
 *      is the merkleRoot of all block hashes contained in the proof, which may
 *      commit to many merkle roots which to commit on chain. If the last block
 *      is recent enough (<= 256 blocks old), the lastHash can be confirmed in
 *      the EVM, verifying that all blocks of the proof belong to this chain.
 *      Due to this, the historical blocks' merkle roots are imported in reverse
 *      order.
 */
contract BlockHistory is Ownable, IBlockHistory {
    // depth of the merkle trees whose roots we store in storage
    uint256 private constant MERKLE_TREE_DEPTH = 13;
    uint256 private constant BLOCKS_PER_CHUNK = 1 << MERKLE_TREE_DEPTH;

    /// @dev address of the reliquary, immutable
    address public immutable reliquary;

    /// @dev the expected signer of the SNARK proofs - if 0, then no signatures
    address public signer;

    /// @dev maps numBlocks => SNARK verifier (with VK embedded), only assigned
    ///      to in the constructor
    mapping(uint256 => IRecursiveVerifier) public verifiers;

    /// @dev parent hash of oldest block in current merkle trees
    ///      (0 once backlog fully imported)
    bytes32 public parentHash;

    /// @dev the earliest merkle root that has been imported
    uint256 public earliestRoot;

    /// @dev hash of most recent block in merkle trees
    bytes32 public lastHash;

    /// @dev merkle roots of block chunks between parentHash and lastHash
    mapping(uint256 => bytes32) private merkleRoots;

    event ImportMerkleRoot(uint256 indexed index, bytes32 merkleRoot);
    event NewSigner(address newSigner);

    enum ProofType {
        Merkle,
        SNARK
    }

    /// @dev A SNARK + Merkle proof used to prove validity of a block
    struct ValidBlockSNARK {
        uint256 numBlocks;
        uint256 endBlock;
        SignedRecursiveProof snark;
        bytes32[] merkleProof;
    }

    constructor(
        uint256[] memory sizes,
        IRecursiveVerifier[] memory _verifiers,
        address _reliquary
    ) Ownable() {
        reliquary = _reliquary;

        require(sizes.length == _verifiers.length);
        for (uint256 i = 0; i < sizes.length; i++) {
            require(address(verifiers[sizes[i]]) == address(0));
            verifiers[sizes[i]] = _verifiers[i];
        }
    }

    /**
     * @notice Checks if a SNARK is valid and signed as expected.
     *         Signatures checks are disabled if stored signer == address(0)
     *         Properties proven by the SNARK:
     *         - (parent ... last) form a valid block chain of length numBlocks
     *         - root is the merkle root of all contained blocks
     *
     * @param proof the aggregated proof
     * @param numBlocks the number of blocks contained in the proof
     * @return the validity
     */
    function validSNARK(SignedRecursiveProof calldata proof, uint256 numBlocks)
        internal
        view
        returns (bool)
    {
        address expected = signer;
        if (expected != address(0) && getProofSigner(proof) != expected) {
            return false;
        }
        IRecursiveVerifier verifier = verifiers[numBlocks];
        require(address(verifier) != address(0), "invalid numBlocks");
        return verifier.verify(proof.inner);
    }

    /**
     * @notice Asserts that the provided SNARK proof is valid and contains
     *         the provied merkle roots.
     *
     * @param proof the aggregated proof
     * @param roots the merkle roots
     * @return parent the parentHash of the proof blocks
     * @return last the lastHash of the proof blocks
     */
    function assertValidSNARKWithRoots(
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots
    ) internal view returns (bytes32 parent, bytes32 last) {
        require(roots.length & (roots.length - 1) == 0, "roots length must be a power of 2");

        // extract the inputs from the proof
        bytes32 proofRoot;
        (parent, last, proofRoot) = parseProofInputs(proof);

        // ensure the merkle roots are valid
        require(proofRoot == MerkleTree.computeRoot(roots), "invalid roots");

        // assert the SNARK proof is valid
        require(validSNARK(proof, BLOCKS_PER_CHUNK * roots.length), "invalid SNARK");
    }

    /**
     * @notice Checks if the given block number/hash connects to the current
     *         block using a SNARK.
     *
     * @param num the block number to check
     * @param hash the block hash to check
     * @param encodedProof the encoded ValidBlockSNARK
     * @return the validity
     */
    function validBlockHashWithSNARK(
        bytes32 hash,
        uint256 num,
        bytes calldata encodedProof
    ) internal view returns (bool) {
        ValidBlockSNARK calldata proof = parseValidBlockSNARK(encodedProof);

        (bytes32 proofParent, bytes32 proofLast, bytes32 proofRoot) = parseProofInputs(proof.snark);

        // check that the proof ends with a current block
        if (!validCurrentBlock(proofLast, proof.endBlock)) {
            return false;
        }

        if (!validSNARK(proof.snark, proof.numBlocks)) {
            return false;
        }

        // compute the first block number in the proof
        uint256 startBlock = proof.endBlock + 1 - proof.numBlocks;

        // check if the target block is the parent of the proven blocks
        if (num == startBlock - 1 && hash == proofParent) {
            // merkle proof not needed in this case
            return true;
        }

        // check if the target block is in the proven merkle root
        uint256 index = num - startBlock;
        return MerkleTree.validProof(proofRoot, index, hash, proof.merkleProof);
    }

    /**
     * @notice Checks if the given block number + hash exists in a commited
     *         merkle tree.
     *
     * @param num the block number to check
     * @param hash the block hash to check
     * @param encodedProof the encoded merkle proof
     * @return the validity
     */
    function validBlockHashWithMerkle(
        bytes32 hash,
        uint256 num,
        bytes calldata encodedProof
    ) internal view returns (bool) {
        bytes32 merkleRoot = merkleRoots[num / BLOCKS_PER_CHUNK];
        if (merkleRoot == 0) {
            return false;
        }
        bytes32[] calldata proofHashes = parseMerkleProof(encodedProof);
        if (proofHashes.length != MERKLE_TREE_DEPTH) {
            return false;
        }
        return MerkleTree.validProof(merkleRoot, num % BLOCKS_PER_CHUNK, hash, proofHashes);
    }

    /**
     * @notice Checks if the block is a current block (defined as being
     *         accessible in the EVM, i.e. <= 256 blocks old) and that the hash
     *         is correct.
     *
     * @param hash the alleged block hash
     * @param num the block number
     * @return the validity
     */
    function validCurrentBlock(bytes32 hash, uint256 num) internal view returns (bool) {
        // the block hash must be accessible in the EVM and match
        return (block.number - num <= 256) && (blockhash(num) == hash);
    }

    /**
     * @notice Stores the merkle roots starting at the index
     *
     * @param index the index for the first merkle root
     * @param roots the merkle roots
     */
    function storeMerkleRoots(uint256 index, bytes32[] calldata roots) internal {
        for (uint256 i = 0; i < roots.length; i++) {
            merkleRoots[index + i] = roots[i];
            emit ImportMerkleRoot(index + i, roots[i]);
        }
    }

    /**
     * @notice Imports new chunks of blocks before the current parentHash
     *
     * @param proof the aggregated proof for these chunks
     * @param roots the merkle roots for the chunks
     */
    function importParent(SignedRecursiveProof calldata proof, bytes32[] calldata roots) external {
        require(parentHash != 0 && earliestRoot != 0, "import not started or already completed");

        (bytes32 proofParent, bytes32 proofLast) = assertValidSNARKWithRoots(proof, roots);

        // assert the last hash in the proof is our current parent hash
        require(parentHash == proofLast, "proof doesn't connect with parentHash");

        // store the merkle roots
        uint256 index = earliestRoot - roots.length;
        storeMerkleRoots(index, roots);

        // store the new parentHash and earliestRoot
        parentHash = proofParent;
        earliestRoot = index;
    }

    /**
     * @notice Imports new chunks of blocks after the current lastHash
     *
     * @param endBlock the last block number in the chunks
     * @param proof the aggregated proof for these chunks
     * @param roots the merkle roots for the chunks
     * @param connectProof an optional SNARK proof connecting the proof to
     *                     a current block
     */
    function importLast(
        uint256 endBlock,
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots,
        bytes calldata connectProof
    ) external {
        require((endBlock + 1) % BLOCKS_PER_CHUNK == 0, "endBlock must end at a chunk boundary");

        (bytes32 proofParent, bytes32 proofLast) = assertValidSNARKWithRoots(proof, roots);

        if (!validCurrentBlock(proofLast, endBlock)) {
            // if the proof doesn't connect our lastHash with a current block,
            // then the connectProof must fill the gap
            require(
                validBlockHashWithSNARK(proofLast, endBlock, connectProof),
                "connectProof invalid"
            );
        }

        uint256 index = (endBlock + 1) / BLOCKS_PER_CHUNK - roots.length;
        if (lastHash == 0) {
            // if we're importing for the first time, set parentHash and earliestRoot
            require(parentHash == 0);
            parentHash = proofParent;
            earliestRoot = index;
        } else {
            require(proofParent == lastHash, "proof doesn't connect with lastHash");
        }

        // store the new lastHash
        lastHash = proofLast;

        // store the merkle roots
        storeMerkleRoots(index, roots);
    }

    /**
     * @notice Checks if a block hash is valid. A proof is required unless the
     *         block is current (accesible in the EVM). If the target block has
     *         no commited merkle root, the proof must contain a SNARK proof.
     *
     * @param hash the hash to check
     * @param num the block number for the alleged hash
     * @param proof the merkle witness or SNARK proof (if needed)
     * @return the validity
     */
    function _validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) internal view returns (bool) {
        if (validCurrentBlock(hash, num)) {
            return true;
        }

        ProofType typ;
        (typ, proof) = parseProofType(proof);
        if (typ == ProofType.Merkle) {
            return validBlockHashWithMerkle(hash, num, proof);
        } else if (typ == ProofType.SNARK) {
            return validBlockHashWithSNARK(hash, num, proof);
        } else {
            revert("invalid proof type");
        }
    }

    /**
     * @notice Checks if a block hash is correct. A proof is required unless the
     *         block is current (accesible in the EVM). If the target block has
     *         no commited merkle root, the proof must contain a SNARK proof.
     *         Reverts if block hash or proof is invalid.
     *
     * @param hash the hash to check
     * @param num the block number for the alleged hash
     * @param proof the merkle witness or SNARK proof (if needed)
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool) {
        require(msg.sender == reliquary || msg.sender == owner());
        require(num < block.number);
        return _validBlockHash(hash, num, proof);
    }

    /**
     * @notice Parses a proof type and proof from the encoded proof
     *
     * @param proof the encoded proof
     * @return typ the proof type (SNARK or Merkle)
     * @return proof the remaining encoded proof
     */
    function parseProofType(bytes calldata encodedProof)
        internal
        pure
        returns (ProofType typ, bytes calldata proof)
    {
        require(encodedProof.length > 0, "cannot parse proof type");
        typ = ProofType(uint8(encodedProof[0]));
        proof = encodedProof[1:];
    }

    /**
     * @notice Parses a ValidBlockSNARK from calldata bytes
     *
     * @param proof the encoded proof
     * @return result a ValidBlockSNARK
     */
    function parseValidBlockSNARK(bytes calldata proof)
        internal
        pure
        returns (ValidBlockSNARK calldata result)
    {
        // solidity doesn't support getting calldata outputs from abi.decode
        // but we can decode it; calldata structs are just offsets
        assembly {
            result := proof.offset
        }
    }

    /**
     * @notice Parses a merkle inclusion proof from the bytes
     *
     * @param proof the encoded merkle inclusion proof
     * @return result the array of proof hashes
     */
    function parseMerkleProof(bytes calldata proof)
        internal
        pure
        returns (bytes32[] calldata result)
    {
        require(proof.length % 32 == 0);
        require(proof.length >= 32);

        // solidity doesn't support getting calldata outputs from abi.decode
        // but we can decode it; calldata arrays are just (offset,length)
        assembly {
            result.offset := add(proof.offset, 0x20)
            result.length := calldataload(proof.offset)
        }
    }

    /**
     * @notice Parses the proof inputs for block history snark proofs
     *
     * @param proof the snark proof
     * @return proofParent the parentHash of the proof blocks
     * @return proofLast the lastHash of the proof blocks
     * @return proofRoot the merkle root of the proof blocks
     */
    function parseProofInputs(SignedRecursiveProof calldata proof)
        internal
        pure
        returns (
            bytes32 proofParent,
            bytes32 proofLast,
            bytes32 proofRoot
        )
    {
        uint256[] calldata inputs = proof.inner.inputs;
        require(inputs.length == 12);
        proofParent = readHashWords(inputs[0:4]);
        proofLast = readHashWords(inputs[4:8]);
        proofRoot = readHashWords(inputs[8:12]);
    }

    /**
     * @notice sets the expected signer of the SNARK proofs, only callable by
     *         the contract owner
     *
     * @param _signer the new signer; if 0, disables signature checks
     */
    function setSigner(address _signer) external onlyOwner {
        require(signer != _signer);
        signer = _signer;
        emit NewSigner(_signer);
    }
}