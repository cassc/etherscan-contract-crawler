// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/// Keeps a list of rng batches
/// After n new items minted, where n == batchSize, a new rng value is commited
/// This allows an NFT to use randomness on a per-batch basis, where every new n items are revealed
/// and shuffled within the batch bounds, while keeping future items still unrevealed
abstract contract RandomnessBatches {
    uint256 public constant REVEAL_GRACE_PERIOD = 2 weeks;

    error BatchAlreadyRevealed();
    error RNGInvalidArgs();
    error GracePeriodNotOverYet();
    error BatchNotFullYet();

    uint128 immutable maxSupply;
    uint128 immutable batchSize;
    uint256 public immutable revealGracePeriodEnd;

    uint256 xyz;
    uint256[] public randomness;
    bytes32 public rng;

    /// @param _maxSupply Max supply of items to be expected
    /// @param _batchSize Size of each batch
    /// @param _revealGracePeriodStart the point from which REVEAL_GRACE_PERIOD starts counting for anyone to be able to reveal fully minted batches
    constructor(
        uint128 _maxSupply,
        uint128 _batchSize,
        uint256 _revealGracePeriodStart
    ) {
        maxSupply = _maxSupply;
        batchSize = _batchSize;
        uint256 batches = ceilDiv(_maxSupply, _batchSize);
        randomness = new uint256[](batches);
        rng = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        revealGracePeriodEnd = _revealGracePeriodStart + REVEAL_GRACE_PERIOD;
    }

    /// Plug to incrementaly build randomness on every new mint
    modifier rngContribute() {
        rng ^= keccak256(abi.encodePacked(msg.sender, block.timestamp, rng));
        _;
    }

    //
    // Public API
    //

    /// For a given id bound between [0, maxSupply],
    /// check if its batch has been revealed.
    /// If so, return the final shuffled ID,  otherwise 0
    ///
    /// @param _id The original sequencial id to shuffle
    function shuffleID(uint256 _id) public view returns (uint256) {
        uint256 localBatchSize = batchSize;

        // slither-disable-next-line divide-before-multiply
        uint256 idx = (uint128(_id) / localBatchSize);
        uint256 rand = uint256(randomness[idx]);

        // the last batch may have less than `batchSize` elements
        // so computations are slightly different
        bool isLastBatch = idx == getBatchCount() - 1;
        uint256 currentBatchSize = isLastBatch
            ? (maxSupply % localBatchSize)
            : localBatchSize;

        // slither-disable-next-line incorrect-equality
        if (rand == 0) {
            return 0;
        } else {
            uint256 batchOffset = idx * localBatchSize;
            uint256 shuffled = ((_id + rand) % currentBatchSize);

            // we want IDs to have the range 1..maxSupply, not 0..(maxSupply-1),
            // so we add one more
            return batchOffset + shuffled + 1;
        }
    }

    /// For a given shuffled id bound between [0, maxSupply],
    /// computes the corresponding on-chain ID.
    ///
    /// @param _shuffledId The shuffled ID, from off-chain metadata
    /// @return id The original on-chain ID
    function unshuffleId(uint256 _shuffledId)
        external
        view
        returns (uint256 id)
    {
        uint256 localBatchSize = batchSize;
        uint256 batch = (_shuffledId - 1) / localBatchSize;
        uint256 rand = uint256(randomness[batch]);

        if (rand == 0) {
            // batch not revealed yet
            return 0;
        }

        bool isLastBatch = batch == getBatchCount() - 1;
        uint256 currentBatchSize = isLastBatch
            ? (maxSupply % localBatchSize)
            : localBatchSize;

        uint256 offset = (currentBatchSize - rand) % currentBatchSize;
        return
            (batch * localBatchSize) +
            ((_shuffledId - 1 + offset) % currentBatchSize);
    }

    function getBatchCount() public view returns (uint256) {
        return randomness.length;
    }

    //
    // Internal API
    //

    /// Internal function to reveal a batch, either once its filled,
    /// or by force from a role-only call
    function _rngReveal(uint256 _batchIdx) internal {
        // slither-disable-next-line incorrect-equality
        if (randomness[_batchIdx] == 0) {
            randomness[_batchIdx] = (uint256(rng) % batchSize) + 1;
        }
    }

    /// Check if a new batch has been filled.
    /// If so, we commit its randomness, revealing it
    function _rngTryReveal(uint256 _batchIdx, uint256 _totalSupply) internal {
        if (block.timestamp < revealGracePeriodEnd) {
            revert GracePeriodNotOverYet();
        }

        if (_totalSupply == maxSupply) {
            _rngReveal(_batchIdx);
            return;
        }

        uint256 minSupply = (_batchIdx + 1) * batchSize;

        if (_totalSupply < minSupply) {
            revert BatchNotFullYet();
        }

        _rngReveal(_batchIdx);
    }

    function ceilDiv(uint256 a, uint256 m) internal pure returns (uint256) {
        // slither-disable-next-line divide-before-multiply
        uint256 result = a / m;
        if (result * m < a) {
            return result + 1;
        } else {
            return result;
        }
    }
}