/**
 *Submitted for verification at Etherscan.io on 2023-04-13
*/

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

// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION

interface IAccountAge {
    /// @notice Mapping between EOA address => block number of first transaction
    function birthBlocks(address) external view returns (uint32);

    event AccountAgeProof(address account, uint32 blockNumber);

    /// @notice Verify a ZK proof of account age using Axiom.
    ///         Caches the account age value for future use.
    function verifyAge(
        IAxiomV0.BlockHashWitness calldata prevBlock,
        IAxiomV0.BlockHashWitness calldata currBlock,
        bytes calldata proof
    ) external;
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

contract AccountAgeV02 is Ownable, IAccountAge {
    string public constant VERSION = "0.2";

    address public axiomAddress;
    address public verifierAddress;

    mapping(address => uint32) public birthBlocks;

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

    // TODO: prevBlock witness is not needed - it is already checked in ZKP
    function verifyAge(
        IAxiomV0.BlockHashWitness calldata prevBlock,
        IAxiomV0.BlockHashWitness calldata currBlock,
        bytes calldata proof
    ) external {
        if (block.number - prevBlock.blockNumber <= 256) {
            if (!IAxiomV0(axiomAddress).isRecentBlockHashValid(prevBlock.blockNumber, prevBlock.claimedBlockHash)) {
                revert("Prev block hash was not validated in cache");
            }
        } else {
            if (!IAxiomV0(axiomAddress).isBlockHashValid(prevBlock)) {
                revert("Prev block hash was not validated in cache");
            }
        }
        if (block.number - currBlock.blockNumber <= 256) {
            if (!IAxiomV0(axiomAddress).isRecentBlockHashValid(currBlock.blockNumber, currBlock.claimedBlockHash)) {
                revert("Curr block hash was not validated in cache");
            }
        } else {
            if (!IAxiomV0(axiomAddress).isBlockHashValid(currBlock)) {
                revert("Curr block hash was not validated in cache");
            }
        }

        // Extract instances from proof
        uint256 _prevBlockHash =
            uint256(bytes32(proof[384:384 + 32])) << 128 | uint128(bytes16(proof[384 + 48:384 + 64]));
        uint256 _currBlockHash =
            uint256(bytes32(proof[384 + 64:384 + 96])) << 128 | uint128(bytes16(proof[384 + 112:384 + 128]));
        uint256 _blockNumber = uint256(bytes32(proof[384 + 128:384 + 160]));
        address account = address(bytes20(proof[384 + 172:384 + 204]));

        // Check instance values
        if (_prevBlockHash != uint256(prevBlock.claimedBlockHash)) {
            revert("Invalid previous block hash in instance");
        }
        if (_currBlockHash != uint256(currBlock.claimedBlockHash)) {
            revert("Invalid current block hash in instance");
        }
        if (_blockNumber != currBlock.blockNumber) {
            revert("Invalid block number");
        }

        // Verify the following statement:
        //   nonce(account, blockNumber - 1) == 0 AND
        //   nonce(account, blockNumber) != 0     AND
        //   codeHash(account, blockNumber) == keccak256([])
        (bool success,) = verifierAddress.call(proof);
        if (!success) {
            revert("Proof verification failed");
        }
        birthBlocks[account] = currBlock.blockNumber;
        emit AccountAgeProof(account, currBlock.blockNumber);
    }
}