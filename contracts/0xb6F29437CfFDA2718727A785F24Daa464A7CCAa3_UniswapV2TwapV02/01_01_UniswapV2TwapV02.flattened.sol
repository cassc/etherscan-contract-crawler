// SPDX-License-Identifier: MIT
// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
pragma solidity ^0.8.12;

// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION

interface IAxiomV0 {
    // historicalRoots(startBlockNumber) is 0 unless (startBlockNumber % 1024 == 0)
    // historicalRoots(startBlockNumber) holds the hash of
    //   prevHash || root || numFinal
    // where
    // - prevHash is the parent hash of block startBlockNumber
    // - root is the partial Merkle root of blockhashes of block numbers
    //   [startBlockNumber, startBlockNumber + 1024)
    //   where unconfirmed block hashes are 0's
    // - numFinal is the number of confirmed consecutive roots in [startBlockNumber, startBlockNumber + 1024)
    function historicalRoots(uint32 startBlockNumber) external view returns (bytes32);

    event UpdateEvent(uint32 startBlockNumber, bytes32 prevHash, bytes32 root, uint32 numFinal);

    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[10] merkleProof;
    }

    // returns Merkle root of a tree of depth `depth` with 0's as leaves
    function getEmptyHash(uint256 depth) external pure returns (bytes32);

    // update blocks in the "backward" direction, anchoring on a "recent" end blockhash that is within last 256 blocks
    // * startBlockNumber must be a multiple of 1024
    // * roots[idx] is the root of a Merkle tree of height 2**(10 - idx) in a Merkle mountain
    //   range which stores block hashes in the interval [startBlockNumber, endBlockNumber]
    function updateRecent(bytes calldata proofData) external;

    // update older blocks in "backwards" direction, anchoring on more recent trusted blockhash
    // must be batch of 1024 blocks
    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external;

    // Update older blocks in "backwards" direction, anchoring on more recent trusted blockhash
    // Must be batch of 128 * 1024 blocks
    // `roots` should contain 128 merkle roots, one per batch of 1024 blocks
    // For all except the last batch of 1024 blocks, a Merkle inclusion proof of the `endHash` of the batch
    // must be provided, with respect to the corresponding Merkle root in `roots`
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[128] calldata roots,
        bytes32[11][127] calldata endHashProofs,
        bytes calldata proofData
    ) external;

    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) external view returns (bool);
    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION

interface IUniswapV2TwapV0 {
    /// @notice Mapping between abi.encodePacked(address poolAddress, uint32 startBlockNumber, uint32 endBlockNumber) => twapPri (uint256)
    function twapPris(bytes28) external view returns (uint256);

    event UniswapV2TwapProof(address pairAddress, uint32 startBlockNumber, uint32 endBlockNumber, uint256 twapPri);

    /// @notice Verify a ZK proof of a Uniswap V2 TWAP computation and verifies the validity of checkpoint blockhashes using Axiom.
    ///         Caches the TWAP price value for future use.
    ///         Returns the time (seconds) weighted average price (arithmetic mean)
    function verifyUniswapV2Twap(
        IAxiomV0.BlockHashWitness calldata startBlock,
        IAxiomV0.BlockHashWitness calldata endBlock,
        bytes calldata proof
    ) external returns (uint256 twapPri);
}

contract UniswapV2TwapV02 is Ownable, IUniswapV2TwapV0 {
    string public constant VERSION = "0.2";

    address public axiomAddress;
    address public verifierAddress;

    // mapping between abi.encodePacked(address poolAddress, uint32 startBlockNumber, uint32 endBlockNumber) => twapPri (uint256)
    mapping(bytes28 => uint256) public twapPris;

    event UpdateAxiomAddress(address newAddress);
    event UpdateSnarkVerifierAddress(address newAddress);

    constructor(address _axiomAddress, address _verifierAddress) {
        axiomAddress = _axiomAddress;
        verifierAddress = _verifierAddress;
    }

    function updateAxiomAddress(address _axiomAddress) external onlyOwner {
        axiomAddress = _axiomAddress;
        emit UpdateAxiomAddress(_axiomAddress);
    }

    function updateSnarkVerifierAddress(address _verifierAddress) external onlyOwner {
        verifierAddress = _verifierAddress;
        emit UpdateSnarkVerifierAddress(_verifierAddress);
    }

    // The public inputs and outputs of the ZK proof
    struct Instance {
        address pairAddress;
        uint32 startBlockNumber;
        uint32 endBlockNumber;
        bytes32 startBlockHash;
        bytes32 endBlockHash;
        uint256 twapPri;
    }

    function getProofInstance(bytes calldata proof) internal pure returns (Instance memory instance) {
        // Public instances: total 6 field elements
        // * 0: `pair_address . start_block_number . end_block_number` is `20 + 4 + 4 = 28` bytes, packed into a single field element
        // * 1..3: `start_block_hash` (32 bytes) is split into two field elements (hi, lo u128)
        // * 3..5: `end_block_hash` (32 bytes) is split into two field elements (hi, lo u128)
        // * 5: `twap_pri` (32 bytes) is single field element representing the computed TWAP
        bytes32[6] memory fieldElements;
        // The first 4 * 3 * 32 bytes give two elliptic curve points for internal pairing check
        uint256 start = 384;
        for (uint256 i = 0; i < 6; i++) {
            fieldElements[i] = bytes32(proof[start:start + 32]);
            start += 32;
        }
        instance.pairAddress = address(bytes20(fieldElements[0] << 32)); // 4 * 8, bytes is right padded so conversion is from left
        instance.startBlockNumber = uint32(bytes4(fieldElements[0] << 192)); // 24 * 8
        instance.endBlockNumber = uint32(bytes4(fieldElements[0] << 224)); // 28 * 8
        instance.startBlockHash = bytes32((uint256(fieldElements[1]) << 128) | uint128(uint256(fieldElements[2])));
        instance.endBlockHash = bytes32((uint256(fieldElements[3]) << 128) | uint128(uint256(fieldElements[4])));
        instance.twapPri = uint256(fieldElements[5]);
    }

    function validateBlockHash(IAxiomV0.BlockHashWitness calldata witness) internal view {
        if (block.number - witness.blockNumber <= 256) {
            if (!IAxiomV0(axiomAddress).isRecentBlockHashValid(witness.blockNumber, witness.claimedBlockHash)) {
                revert("BlockHashWitness is not validated by Axiom");
            }
        } else {
            if (!IAxiomV0(axiomAddress).isBlockHashValid(witness)) {
                revert("BlockHashWitness is not validated by Axiom");
            }
        }
    }

    function verifyUniswapV2Twap(
        IAxiomV0.BlockHashWitness calldata startBlock,
        IAxiomV0.BlockHashWitness calldata endBlock,
        bytes calldata proof
    ) external returns (uint256) {
        Instance memory instance = getProofInstance(proof);
        // compare calldata vs proof instances:
        if (instance.startBlockNumber > instance.endBlockNumber) {
            revert("startBlockNumber <= endBlockNumber");
        }
        if (instance.startBlockNumber != startBlock.blockNumber) {
            revert("instance.startBlockNumber != startBlock.blockNumber");
        }
        if (instance.endBlockNumber != endBlock.blockNumber) {
            revert("instance.endBlockNumber != endBlock.blockNumber");
        }
        if (instance.startBlockHash != startBlock.claimedBlockHash) {
            revert("instance.startBlockHash != startBlock.claimedBlockHash");
        }
        if (instance.endBlockHash != endBlock.claimedBlockHash) {
            revert("instance.endBlockHash != endBlock.claimedBlockHash");
        }
        // Use Axiom to validate block hashes
        validateBlockHash(startBlock);
        validateBlockHash(endBlock);

        (bool success,) = verifierAddress.call(proof);
        if (!success) {
            revert("Proof verification failed");
        }
        twapPris[bytes28(abi.encodePacked(instance.pairAddress, instance.startBlockNumber, instance.endBlockNumber))] =
            instance.twapPri;
        emit UniswapV2TwapProof(instance.pairAddress, startBlock.blockNumber, endBlock.blockNumber, instance.twapPri);
        return instance.twapPri;
    }
}