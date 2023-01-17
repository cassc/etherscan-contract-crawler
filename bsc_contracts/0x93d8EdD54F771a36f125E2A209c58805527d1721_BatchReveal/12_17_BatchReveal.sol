//SPDX-License-Identifier: CC0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./chainlink/VRFConsumerBaseV2Upgradeable.sol";
import "./interfaces/IBatchReveal.sol";
import "./interfaces/IBaseLaunchpeg.sol";
import "./LaunchpegErrors.sol";

// Creator: Tubby Cats
/// https://github.com/tubby-cats/batch-nft-reveal

/// @title BatchReveal
/// @notice Implements a gas efficient way of revealing NFT URIs gradually
contract BatchReveal is
    IBatchReveal,
    VRFConsumerBaseV2Upgradeable,
    OwnableUpgradeable
{
    /// @notice Batch reveal configuration by launchpeg
    mapping(address => BatchRevealConfig) public override launchpegToConfig;

    /// @notice VRF request ids by launchpeg
    mapping(uint256 => address) public vrfRequestIdToLaunchpeg;

    /// @notice Randomized seeds used to shuffle TokenURIs by launchpeg
    mapping(address => mapping(uint256 => uint256))
        public
        override launchpegToBatchToSeed;

    /// @notice Last token that has been revealed by launchpeg
    mapping(address => uint256) public override launchpegToLastTokenReveal;

    /// @dev Size of the array that will store already taken URIs numbers by launchpeg
    mapping(address => uint256) public launchpegToRangeLength;

    /// @notice Contract uses VRF or pseudo-randomness
    bool public override useVRF;

    /// @notice Chainlink subscription ID
    uint64 public override subscriptionId;

    /// @notice The gas lane to use, which specifies the maximum gas price to bump to.
    /// For a list of available gas lanes on each network,
    /// see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public override keyHash;

    /// @notice Depends on the number of requested values that you want sent to the
    /// fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    /// so 100,000 is a safe default for this example contract. Test and adjust
    /// this limit based on the network that you select, the size of the request,
    /// and the processing of the callback request in the fulfillRandomWords()
    /// function.
    uint32 public override callbackGasLimit;

    /// @notice Number of block confirmations that the coordinator will wait before triggering the callback
    /// The default is 3
    uint16 public constant override requestConfirmations = 3;

    /// @notice Next batch that will be revealed by VRF (if activated) by launchpeg
    mapping(address => uint256) public override launchpegToNextBatchToReveal;

    /// @notice True when force revealed has been triggered for the given launchpeg
    /// @dev VRF will not be used anymore if a batch has been force revealed
    mapping(address => bool) public override launchpegToHasBeenForceRevealed;

    /// @notice Has the random number for a batch already been asked by launchpeg
    /// @dev Prevents people from spamming the random words request
    /// and therefore reveal more batches than expected
    mapping(address => mapping(uint256 => bool))
        public
        override launchpegToVrfRequestedForBatch;

    struct Range {
        int128 start;
        int128 end;
    }

    /// @dev Emitted on revealNextBatch() and forceReveal()
    /// @param baseLaunchpeg Base launchpeg address
    /// @param batchNumber The batch revealed
    /// @param batchSeed The random number drawn
    event Reveal(address baseLaunchpeg, uint256 batchNumber, uint256 batchSeed);

    /// @dev Emitted on setRevealBatchSize()
    /// @param baseLaunchpeg Base launchpeg address
    /// @param revealBatchSize New reveal batch size
    event RevealBatchSizeSet(address baseLaunchpeg, uint256 revealBatchSize);

    /// @dev Emitted on setRevealStartTime()
    /// @param baseLaunchpeg Base launchpeg address
    /// @param revealStartTime New reveal start time
    event RevealStartTimeSet(address baseLaunchpeg, uint256 revealStartTime);

    /// @dev Emitted on setRevealInterval()
    /// @param baseLaunchpeg Base launchpeg address
    /// @param revealInterval New reveal interval
    event RevealIntervalSet(address baseLaunchpeg, uint256 revealInterval);

    /// @dev emitted on setVRF()
    /// @param _vrfCoordinator Chainlink coordinator address
    /// @param _keyHash Keyhash of the gas lane wanted
    /// @param _subscriptionId Chainlink subscription ID
    /// @param _callbackGasLimit Max gas used by the coordinator callback
    event VRFSet(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    );

    /// @dev Verify that batch reveal is configured for the given launchpeg
    modifier batchRevealInitialized(address _baseLaunchpeg) {
        if (!isBatchRevealInitialized(_baseLaunchpeg)) {
            revert Launchpeg__BatchRevealNotInitialized();
        }
        _;
    }

    /// @dev Verify that batch reveal hasn't started for the given launchpeg
    modifier revealNotStarted(address _baseLaunchpeg) {
        if (launchpegToLastTokenReveal[_baseLaunchpeg] != 0) {
            revert Launchpeg__BatchRevealStarted();
        }
        _;
    }

    /// @notice Initialize batch reveal
    function initialize() external override initializer {
        __Ownable_init();
    }

    /// @dev Configure batch reveal for a given launch
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealBatchSize Size of the batch reveal
    /// @param _revealStartTime Batch reveal start time
    /// @param _revealInterval Batch reveal interval
    function configure(
        address _baseLaunchpeg,
        uint256 _revealBatchSize,
        uint256 _revealStartTime,
        uint256 _revealInterval
    ) external override onlyOwner revealNotStarted(_baseLaunchpeg) {
        uint256 _collectionSize = IBaseLaunchpeg(_baseLaunchpeg)
            .collectionSize();
        launchpegToConfig[_baseLaunchpeg].collectionSize = _collectionSize;
        launchpegToConfig[_baseLaunchpeg].intCollectionSize = int128(
            int256(_collectionSize)
        );
        _setRevealBatchSize(_baseLaunchpeg, _revealBatchSize);
        _setRevealStartTime(_baseLaunchpeg, _revealStartTime);
        _setRevealInterval(_baseLaunchpeg, _revealInterval);
    }

    /// @notice Set the reveal batch size. Can only be set after
    /// batch reveal has been initialized and before a batch has
    /// been revealed.
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealBatchSize New reveal batch size
    function setRevealBatchSize(
        address _baseLaunchpeg,
        uint256 _revealBatchSize
    )
        public
        override
        onlyOwner
        batchRevealInitialized(_baseLaunchpeg)
        revealNotStarted(_baseLaunchpeg)
    {
        _setRevealBatchSize(_baseLaunchpeg, _revealBatchSize);
    }

    /// @notice Set the reveal batch size
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealBatchSize New reveal batch size
    function _setRevealBatchSize(
        address _baseLaunchpeg,
        uint256 _revealBatchSize
    ) internal {
        if (_revealBatchSize == 0) {
            revert Launchpeg__InvalidBatchRevealSize();
        }
        uint256 collectionSize = launchpegToConfig[_baseLaunchpeg]
            .collectionSize;
        if (
            collectionSize % _revealBatchSize != 0 ||
            _revealBatchSize > collectionSize
        ) {
            revert Launchpeg__InvalidBatchRevealSize();
        }
        launchpegToRangeLength[_baseLaunchpeg] =
            (collectionSize / _revealBatchSize) *
            2;
        launchpegToConfig[_baseLaunchpeg].revealBatchSize = _revealBatchSize;
        emit RevealBatchSizeSet(_baseLaunchpeg, _revealBatchSize);
    }

    /// @notice Set the batch reveal start time. Can only be set after
    /// batch reveal has been initialized and before a batch has
    /// been revealed.
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealStartTime New batch reveal start time
    function setRevealStartTime(
        address _baseLaunchpeg,
        uint256 _revealStartTime
    )
        public
        override
        onlyOwner
        batchRevealInitialized(_baseLaunchpeg)
        revealNotStarted(_baseLaunchpeg)
    {
        _setRevealStartTime(_baseLaunchpeg, _revealStartTime);
    }

    /// @notice Set the batch reveal start time.
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealStartTime New batch reveal start time
    function _setRevealStartTime(
        address _baseLaunchpeg,
        uint256 _revealStartTime
    ) internal {
        // probably a mistake if the reveal is more than 100 days in the future
        if (_revealStartTime > block.timestamp + 8_640_000) {
            revert Launchpeg__InvalidRevealDates();
        }
        launchpegToConfig[_baseLaunchpeg].revealStartTime = _revealStartTime;
        emit RevealStartTimeSet(_baseLaunchpeg, _revealStartTime);
    }

    /// @notice Set the batch reveal interval. Can only be set after
    /// batch reveal has been initialized and before a batch has
    /// been revealed.
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealInterval New batch reveal interval
    function setRevealInterval(address _baseLaunchpeg, uint256 _revealInterval)
        public
        override
        onlyOwner
        batchRevealInitialized(_baseLaunchpeg)
        revealNotStarted(_baseLaunchpeg)
    {
        _setRevealInterval(_baseLaunchpeg, _revealInterval);
    }

    /// @notice Set the batch reveal interval.
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _revealInterval New batch reveal interval
    function _setRevealInterval(address _baseLaunchpeg, uint256 _revealInterval)
        internal
    {
        // probably a mistake if reveal interval is longer than 10 days
        if (_revealInterval > 864_000) {
            revert Launchpeg__InvalidRevealDates();
        }
        launchpegToConfig[_baseLaunchpeg].revealInterval = _revealInterval;
        emit RevealIntervalSet(_baseLaunchpeg, _revealInterval);
    }

    /// @notice Set VRF configuration
    /// @param _vrfCoordinator Chainlink coordinator address
    /// @param _keyHash Keyhash of the gas lane wanted
    /// @param _subscriptionId Chainlink subscription ID
    /// @param _callbackGasLimit Max gas used by the coordinator callback
    function setVRF(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) external override onlyOwner {
        if (_vrfCoordinator == address(0)) {
            revert Launchpeg__InvalidCoordinator();
        }

        (
            ,
            uint32 _maxGasLimit,
            bytes32[] memory s_provingKeyHashes
        ) = VRFCoordinatorV2Interface(_vrfCoordinator).getRequestConfig();

        // 20_000 is the cost of storing one word, callback cost will never be lower than that
        if (_callbackGasLimit > _maxGasLimit || _callbackGasLimit < 20_000) {
            revert Launchpeg__InvalidCallbackGasLimit();
        }

        bool keyHashFound;
        for (uint256 i; i < s_provingKeyHashes.length; i++) {
            if (s_provingKeyHashes[i] == _keyHash) {
                keyHashFound = true;
                break;
            }
        }

        if (!keyHashFound) {
            revert Launchpeg__InvalidKeyHash();
        }

        (, , , address[] memory consumers) = VRFCoordinatorV2Interface(
            _vrfCoordinator
        ).getSubscription(_subscriptionId);

        bool isInConsumerList;
        for (uint256 i; i < consumers.length; i++) {
            if (consumers[i] == address(this)) {
                isInConsumerList = true;
                break;
            }
        }

        if (!isInConsumerList) {
            revert Launchpeg__IsNotInTheConsumerList();
        }

        useVRF = true;
        setVRFConsumer(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;

        emit VRFSet(
            _vrfCoordinator,
            _keyHash,
            _subscriptionId,
            _callbackGasLimit
        );
    }

    // Forked from openzeppelin
    /// @dev Returns the smallest of two numbers.
    /// @param _a First number to consider
    /// @param _b Second number to consider
    /// @return min Minimum between the two params
    function _min(int128 _a, int128 _b) internal pure returns (int128) {
        return _a < _b ? _a : _b;
    }

    /// @notice Fills the range array
    /// @dev Ranges include the start but not the end [start, end)
    /// @param _ranges initial range array
    /// @param _start beginning of the array to be added
    /// @param _end end of the array to be added
    /// @param _lastIndex last position in the range array to consider
    /// @param _intCollectionSize collection size
    /// @return newLastIndex new lastIndex to consider for the future range to be added
    function _addRange(
        Range[] memory _ranges,
        int128 _start,
        int128 _end,
        uint256 _lastIndex,
        int128 _intCollectionSize
    ) private view returns (uint256) {
        uint256 positionToAssume = _lastIndex;
        for (uint256 j; j < _lastIndex; j++) {
            int128 rangeStart = _ranges[j].start;
            int128 rangeEnd = _ranges[j].end;
            if (_start < rangeStart && positionToAssume == _lastIndex) {
                positionToAssume = j;
            }
            if (
                (_start < rangeStart && _end > rangeStart) ||
                (rangeStart <= _start && _end <= rangeEnd) ||
                (_start < rangeEnd && _end > rangeEnd)
            ) {
                int128 length = _end - _start;
                _start = _min(_start, rangeStart);
                _end = _start + length + (rangeEnd - rangeStart);
                _ranges[j] = Range(-1, -1); // Delete
            }
        }
        for (uint256 pos = _lastIndex; pos > positionToAssume; pos--) {
            _ranges[pos] = _ranges[pos - 1];
        }
        _ranges[positionToAssume] = Range(
            _start,
            _min(_end, _intCollectionSize)
        );
        _lastIndex++;
        if (_end > _intCollectionSize) {
            _addRange(
                _ranges,
                0,
                _end - _intCollectionSize,
                _lastIndex,
                _intCollectionSize
            );
            _lastIndex++;
        }
        return _lastIndex;
    }

    /// @dev Adds the last batch into the ranges array
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _lastBatch Batch number to consider
    /// @param _revealBatchSize Reveal batch size
    /// @param _intCollectionSize Collection size
    /// @param _rangeLength Range length
    /// @return ranges Ranges array filled with every URI taken by batches smaller or equal to lastBatch
    function _buildJumps(
        address _baseLaunchpeg,
        uint256 _lastBatch,
        uint256 _revealBatchSize,
        int128 _intCollectionSize,
        uint256 _rangeLength
    ) private view returns (Range[] memory) {
        Range[] memory ranges = new Range[](_rangeLength);
        uint256 lastIndex;
        for (uint256 i; i < _lastBatch; i++) {
            int128 start = int128(
                int256(
                    _getFreeTokenId(
                        _baseLaunchpeg,
                        launchpegToBatchToSeed[_baseLaunchpeg][i],
                        ranges,
                        _intCollectionSize
                    )
                )
            );
            int128 end = start + int128(int256(_revealBatchSize));
            lastIndex = _addRange(
                ranges,
                start,
                end,
                lastIndex,
                _intCollectionSize
            );
        }
        return ranges;
    }

    /// @dev Gets the random token URI number from tokenId
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _startId Token Id to consider
    /// @return uriId Revealed Token URI Id
    function getShuffledTokenId(address _baseLaunchpeg, uint256 _startId)
        external
        view
        override
        returns (uint256)
    {
        int128 intCollectionSize = launchpegToConfig[_baseLaunchpeg]
            .intCollectionSize;
        uint256 revealBatchSize = launchpegToConfig[_baseLaunchpeg]
            .revealBatchSize;
        uint256 batch = _startId / revealBatchSize;
        Range[] memory ranges = new Range[](
            launchpegToRangeLength[_baseLaunchpeg]
        );

        ranges = _buildJumps(
            _baseLaunchpeg,
            batch,
            revealBatchSize,
            intCollectionSize,
            launchpegToRangeLength[_baseLaunchpeg]
        );

        uint256 positionsToMove = (_startId % revealBatchSize) +
            launchpegToBatchToSeed[_baseLaunchpeg][batch];

        return
            _getFreeTokenId(
                _baseLaunchpeg,
                positionsToMove,
                ranges,
                intCollectionSize
            );
    }

    /// @dev Gets the shifted URI number from tokenId and range array
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _positionsToMoveStart Token URI offset if none of the URI Ids were taken
    /// @param _ranges Ranges array built by _buildJumps()
    /// @param _intCollectionSize Collection size
    /// @return uriId Revealed Token URI Id
    function _getFreeTokenId(
        address _baseLaunchpeg,
        uint256 _positionsToMoveStart,
        Range[] memory _ranges,
        int128 _intCollectionSize
    ) private view returns (uint256) {
        int128 positionsToMove = int128(int256(_positionsToMoveStart));
        int128 id;

        for (uint256 round = 0; round < 2; round++) {
            for (uint256 i; i < launchpegToRangeLength[_baseLaunchpeg]; i++) {
                int128 start = _ranges[i].start;
                int128 end = _ranges[i].end;
                if (id < start) {
                    int128 finalId = id + positionsToMove;
                    if (finalId < start) {
                        return uint256(uint128(finalId));
                    } else {
                        positionsToMove -= start - id;
                        id = end;
                    }
                } else if (id < end) {
                    id = end;
                }
            }
            if ((id + positionsToMove) >= _intCollectionSize) {
                positionsToMove -= _intCollectionSize - id;
                id = 0;
            }
        }
        return uint256(uint128(id + positionsToMove));
    }

    /// @dev Sets batch seed for specified batch number
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _batchNumber Batch number that needs to be revealed
    /// @param _collectionSize Collection size
    /// @param _revealBatchSize Reveal batch size
    function _setBatchSeed(
        address _baseLaunchpeg,
        uint256 _batchNumber,
        uint256 _collectionSize,
        uint256 _revealBatchSize
    ) internal {
        uint256 randomness = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );

        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        launchpegToBatchToSeed[_baseLaunchpeg][_batchNumber] =
            randomness %
            (_collectionSize - (_batchNumber * _revealBatchSize));
    }

    /// @dev Returns true if a batch can be revealed
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _totalSupply Number of token already minted
    /// @return hasToRevealInfo Returns a bool saying whether a reveal can be triggered or not
    /// and the number of the next batch that will be revealed
    function hasBatchToReveal(address _baseLaunchpeg, uint256 _totalSupply)
        public
        view
        override
        returns (bool, uint256)
    {
        uint256 revealBatchSize = launchpegToConfig[_baseLaunchpeg]
            .revealBatchSize;
        uint256 revealStartTime = launchpegToConfig[_baseLaunchpeg]
            .revealStartTime;
        uint256 revealInterval = launchpegToConfig[_baseLaunchpeg]
            .revealInterval;
        uint256 lastTokenRevealed = launchpegToLastTokenReveal[_baseLaunchpeg];
        uint256 batchNumber;
        unchecked {
            batchNumber = lastTokenRevealed / revealBatchSize;
        }

        // We don't want to reveal other batches if a VRF random words request is pending
        if (
            block.timestamp < revealStartTime + batchNumber * revealInterval ||
            _totalSupply < lastTokenRevealed + revealBatchSize ||
            launchpegToVrfRequestedForBatch[_baseLaunchpeg][batchNumber]
        ) {
            return (false, batchNumber);
        }

        return (true, batchNumber);
    }

    /// @dev Reveals next batch if possible
    /// @dev If using VRF, the reveal happens on the coordinator callback call
    /// @param _baseLaunchpeg Base launchpeg address
    /// @param _totalSupply Number of token already minted
    /// @return isRevealed Returns false if it is not possible to reveal the next batch
    function revealNextBatch(address _baseLaunchpeg, uint256 _totalSupply)
        external
        override
        returns (bool)
    {
        if (_baseLaunchpeg != msg.sender) {
            revert Launchpeg__Unauthorized();
        }

        uint256 batchNumber;
        bool canReveal;
        (canReveal, batchNumber) = hasBatchToReveal(
            _baseLaunchpeg,
            _totalSupply
        );

        if (!canReveal) {
            return false;
        }

        if (useVRF) {
            uint256 requestId = VRFCoordinatorV2Interface(vrfCoordinator)
                .requestRandomWords(
                    keyHash,
                    subscriptionId,
                    requestConfirmations,
                    callbackGasLimit,
                    1
                );
            vrfRequestIdToLaunchpeg[requestId] = _baseLaunchpeg;
            launchpegToVrfRequestedForBatch[_baseLaunchpeg][batchNumber] = true;
        } else {
            launchpegToLastTokenReveal[_baseLaunchpeg] += launchpegToConfig[
                _baseLaunchpeg
            ].revealBatchSize;
            _setBatchSeed(
                _baseLaunchpeg,
                batchNumber,
                launchpegToConfig[_baseLaunchpeg].collectionSize,
                launchpegToConfig[_baseLaunchpeg].revealBatchSize
            );
            emit Reveal(
                _baseLaunchpeg,
                batchNumber,
                launchpegToBatchToSeed[_baseLaunchpeg][batchNumber]
            );
        }

        return true;
    }

    /// @dev Callback triggered by the VRF coordinator
    /// @param _randomWords Array of random numbers provided by the VRF coordinator
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        address baseLaunchpeg = vrfRequestIdToLaunchpeg[_requestId];

        if (launchpegToHasBeenForceRevealed[baseLaunchpeg]) {
            revert Launchpeg__HasBeenForceRevealed();
        }

        uint256 revealBatchSize = launchpegToConfig[baseLaunchpeg]
            .revealBatchSize;
        uint256 collectionSize = launchpegToConfig[baseLaunchpeg]
            .collectionSize;
        uint256 _batchToReveal = launchpegToNextBatchToReveal[baseLaunchpeg]++;
        uint256 _revealBatchSize = revealBatchSize;
        uint256 _seed = _randomWords[0] %
            (collectionSize - (_batchToReveal * _revealBatchSize));

        launchpegToBatchToSeed[baseLaunchpeg][_batchToReveal] = _seed;
        launchpegToLastTokenReveal[baseLaunchpeg] += _revealBatchSize;

        emit Reveal(
            baseLaunchpeg,
            _batchToReveal,
            launchpegToBatchToSeed[baseLaunchpeg][_batchToReveal]
        );
    }

    /// @dev Force reveal, should be restricted to owner
    function forceReveal(address _baseLaunchpeg) external override onlyOwner {
        uint256 revealBatchSize = launchpegToConfig[_baseLaunchpeg]
            .revealBatchSize;
        uint256 batchNumber;
        unchecked {
            batchNumber =
                launchpegToLastTokenReveal[_baseLaunchpeg] /
                revealBatchSize;
            launchpegToLastTokenReveal[_baseLaunchpeg] += revealBatchSize;
        }

        _setBatchSeed(
            _baseLaunchpeg,
            batchNumber,
            launchpegToConfig[_baseLaunchpeg].collectionSize,
            launchpegToConfig[_baseLaunchpeg].revealBatchSize
        );
        launchpegToHasBeenForceRevealed[_baseLaunchpeg] = true;
        emit Reveal(
            _baseLaunchpeg,
            batchNumber,
            launchpegToBatchToSeed[_baseLaunchpeg][batchNumber]
        );
    }

    /// @notice Returns true if batch reveal is configured for the given launchpeg
    /// Since the collection size is set only when batch reveal is initialized,
    /// and the collection size cannot be 0, we assume a 0 value means
    /// the batch reveal configuration has not been initialized.
    function isBatchRevealInitialized(address _baseLaunchpeg)
        public
        view
        override
        returns (bool)
    {
        return launchpegToConfig[_baseLaunchpeg].collectionSize != 0;
    }
}