// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

// Interfaces
import "./ILiquidPool.sol";
import "./IChainLink.sol";

// Inheritance Contacts
import "./RouterEvents.sol";
import "./AccessControl.sol";
import "./LiquidTransfer.sol";

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 * @author Christoph Krpoun
 */

contract LiquidRouter is LiquidTransfer, AccessControl, RouterEvents {

    // Factory contract that clones liquid pools
    address public factoryAddress;

    // Oracle address for ETH
    address public immutable chainLinkETH;

    // Minimum time for a new merkleRoot to be updated
    uint256 public constant UPDATE_DURATION = 72 hours;

    // Number of last rounds which are checked for heartbeatlength
    uint80 public constant MAX_ROUND_COUNT = 50;

    // Official pools that are added to the router
    mapping(address => bool) public registeredPools;

    // NFT address => merkle root
    mapping(address => bytes32) public merkleRoot;

    // NFT address => merkle root IPFS address
    mapping(address => string) public merkleIPFS;

    // Mapping for ability to expand pools
    mapping(address => bool) public expansionRevoked;

    // Stores the time between chainLink heartbeats
    mapping(address => uint256) public chainLinkHeartBeat;

    // Mapping for updates of merkle roots
    mapping(address => UpdateRoot) public pendingRoots;

    // Mapping for pool expansion with collections
    mapping(address => ExpandPool) public pendingPools;

    // Data object for merkleRoot updates
    struct UpdateRoot {
        uint256 updateTime;
        bytes32 merkleRoot;
        string ipfsAddress;
    }

    // Data object for pool expansion
    struct ExpandPool {
        uint256 updateTime;
        address nftAddress;
    }

    // Marker to avoid unknown pools
    modifier onlyKnownPools(
        address _pool
    ) {
        require(
            registeredPools[_pool] == true,
            "LiquidRouter: UNKNOWN_POOL"
        );
        _;
    }

    // Avoids expansion if denied
    modifier onlyExpandable(
        address _pool
    ) {
        require(
            expansionRevoked[_pool] == false,
            "LiquidRouter: NOT_EXPANDABLE"
        );
        _;
    }

    /**
     * @dev Set the address of the factory, and chainLinkETH oracleAddress
     */
    constructor(
        address _factoryAddress,
        address _chainLinkETH
    ) {

        require(
            _chainLinkETH > address(0),
            "LiquidRouter: EMPTY_ADDRESS"
        );

        factoryAddress = _factoryAddress;
        chainLinkETH = _chainLinkETH;
    }

    /**
     * @dev Calls liquidateNFT on a specific pool. More info see PoolHelper
     * liquidateNFT
     */
    function liquidateNFT(
        address _pool,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
    {
        uint256 auctionPrice = ILiquidPool(_pool).liquidateNFT(
            msg.sender,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            auctionPrice
        );

        emit Liquidated(
            _nftAddress,
            _nftTokenId,
            auctionPrice,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Register an address as officially known pool
     */
    function addLiquidPool(
        address _pool
    )
        external
    {
        require(
            msg.sender == factoryAddress,
            "LiquidRouter: NOT_FACTORY"
        );

        registeredPools[_pool] = true;

        _addWorker(
            _pool,
            multisig
        );

        emit LiquidPoolRegistered(
            _pool,
            block.timestamp
        );
    }

    /**
     * @dev Register initial root for upcoming new collection
     */
    function addMerkleRoot(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsAddress
    )
        external
        onlyMultisig
    {
        require(
            merkleRoot[_nftAddress] == 0,
            "LiquidRouter: OVERWRITE_DENIED"
        );

        _addWorker(
            _nftAddress,
            msg.sender
        );

        merkleRoot[_nftAddress] = _merkleRoot;
        merkleIPFS[_nftAddress] = _ipfsAddress;
    }

    /**
     * @dev Initialise merkle root update for existing collection
     */
    function startUpdateRoot(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsAddress
    )
        external
        onlyWiseWorker(_nftAddress)
    {
        require(
            _merkleRoot > 0,
            "LiquidRouter: INVALID_ROOT"
        );

        uint256 unlockTime = block.timestamp
            + UPDATE_DURATION;

        pendingRoots[_nftAddress] = UpdateRoot({
            updateTime: unlockTime,
            merkleRoot: _merkleRoot,
            ipfsAddress: _ipfsAddress
        });

        emit RootAnnounced(
            msg.sender,
            unlockTime,
            _nftAddress,
            _merkleRoot,
            _ipfsAddress
        );
    }

    /**
     * @dev Finish merkle root update for existing collection after time lock
     */
    function finishUpdateRoot(
        address _nftAddress
    )
        external
    {
        UpdateRoot memory update = pendingRoots[_nftAddress];

        require(
            update.updateTime > 0,
            "LiquidRouter: INVALID_TIME"
        );

        require(
            block.timestamp > update.updateTime,
            "LiquidRouter: TOO_EARLY"
        );

        merkleRoot[_nftAddress] = update.merkleRoot;
        merkleIPFS[_nftAddress] = update.ipfsAddress;

        delete pendingRoots[_nftAddress];

        emit RootUpdated(
            msg.sender,
            block.timestamp,
            _nftAddress,
            update.merkleRoot,
            update.ipfsAddress
        );
    }

    /**
     * @dev Initialise expansion of the pool if allowed and root was announced
     */
    function startExpandPool(
        address _pool,
        address _nftAddress
    )
        external
        onlyExpandable(_pool)
        onlyWiseWorker(_pool)
    {
        require(
            merkleRoot[_nftAddress] > 0,
            "LiquidRouter: ROOT_NOT_SET"
        );

        uint256 updateTime = block.timestamp
            + UPDATE_DURATION;

        pendingPools[_pool] = ExpandPool({
            updateTime: updateTime,
            nftAddress: _nftAddress
        });

        emit UpdateAnnounced(
            msg.sender,
            updateTime,
            _pool,
            _nftAddress
        );
    }

    /**
     * @dev Finish introducing new collection to the pool
     */
    function finishExpandPool(
        address _pool
    )
        external
        onlyExpandable(_pool)
    {
        ExpandPool memory update = pendingPools[_pool];

        require(
            update.updateTime > 0,
            "LiquidRouter: INVALID_TIME"
        );

        require(
            block.timestamp > update.updateTime,
            "LiquidRouter: TOO_EARLY"
        );

        ILiquidPool(_pool).addCollection(
            update.nftAddress
        );

        delete pendingPools[_pool];

        emit PoolUpdated(
            msg.sender,
            block.timestamp,
            _pool,
            update.nftAddress
        );
    }

    /**
     * @dev remove expandability from the pool
     */
    function revokeExpansion(
        address _pool
    )
        external
        onlyMultisig
    {
        expansionRevoked[_pool] = true;

        emit ExpansionRevoked(
            _pool
        );
    }

    /**
     * @dev Calls the depositFunds function of a specific pool.
     * Also handle the transferring of tokens here, only have to approve router
     * Check that pool is registered
     */
    function depositFunds(
        uint256 _amount,
        address _pool
    )
        public
        onlyKnownPools(_pool)
    {
        uint256 shares = ILiquidPool(_pool).depositFunds(
            _amount,
            msg.sender
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            _amount
        );

        emit FundsDeposited(
            _pool,
            msg.sender,
            _amount,
            shares,
            block.timestamp
        );
    }

    /**
     * @dev Calls the withdrawFunds function of a specific pool.
     * more info see LiquidPool withdrawFunds
     */
    function withdrawFunds(
        uint256 _shares,
        address _pool
    )
        public
        onlyKnownPools(_pool)
    {
        uint256 withdrawAmount = ILiquidPool(_pool).withdrawFunds(
            _shares,
            msg.sender
        );

        emit FundsWithdrawn(
            _pool,
            msg.sender,
            withdrawAmount,
            _shares,
            block.timestamp
        );
    }

    /**
     * @dev moves funds as lender from one registered pool
     * to another with requirement being same poolToken
     * uses internalShares and no tokenised Shares
     */
    function moveFunds(
        uint256 _shares,
        address _poolToExit,
        address _poolToEnter
    )
        external
    {
        require(
            ILiquidPool(_poolToExit).poolToken() ==
            ILiquidPool(_poolToEnter).poolToken(),
            "LiquidRouter: TOKENS_MISMATCH"
        );

        uint256 amountToDeposit = ILiquidPool(
            _poolToExit
        ).calculateWithdrawAmount(
            _shares
        );

        withdrawFunds(
            _shares,
            _poolToExit
        );

        depositFunds(
            amountToDeposit,
            _poolToEnter
        );
    }

    /**
     * @dev Calls the borrowFunds function of a specific pool.
     * more info in LiquidPool borrowFunds
     */
    function borrowFunds(
        address _pool,
        uint256 _takeAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        onlyKnownPools(_pool)
    {
        _transferFromNFT(
            msg.sender,
            _pool,
            _nftAddress,
            _nftTokenId
        );

        ILiquidPool(_pool).borrowFunds(
            msg.sender,
            _takeAmount,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        emit FundsBorrowed(
            _pool,
            _nftAddress,
            _nftTokenId,
            _takeAmount,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Calls the borrowMoreFunds function of a specific pool.
     * more info in LiquidPool borrowMoreFunds
     */
    function borrowMoreFunds(
        address _pool,
        uint256 _takeAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        onlyKnownPools(_pool)
    {
        ILiquidPool(_pool).borrowMoreFunds(
            msg.sender,
            _takeAmount,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        emit MoreFundsBorrowed(
            _pool,
            _nftAddress,
            msg.sender,
            _nftTokenId,
            _takeAmount,
            block.timestamp
        );
    }

    /**
     * @dev Calls paybackFunds for a specific pool
     * more info see LiquidPool paybackFunds
     */
    function paybackFunds(
        address _pool,
        uint256 _payAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        onlyKnownPools(_pool)
    {
        uint256 transferAmount = ILiquidPool(_pool).paybackFunds(
            _payAmount,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        address loanOwner = ILiquidPool(_pool).getLoanOwner(
            _nftAddress,
            _nftTokenId
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            transferAmount
        );

        emit FundsReturned(
            _pool,
            _nftAddress,
            loanOwner,
            transferAmount,
            _nftTokenId,
            block.timestamp
        );
    }

    /**
     * @dev Changes the address which
     * receives fees denominated in shares bulk (internal)
     */
    function lockFeeDestination(
        address[] calldata _pools
    )
        external
        onlyMultisig
    {
        for (uint32 i = 0; i < _pools.length; i++) {
            ILiquidPool(_pools[i]).lockFeeDestination();
        }
    }

    /**
     * @dev Changes the address which
     * receives fees denominated in shares bulk
     */
    function changeFeeDestinationAddress(
        address[] calldata _pools,
        address[] calldata _newFeeDestinationAddress
    )
        external
        onlyMultisig
    {
        for (uint32 i = 0; i < _pools.length; i++) {
            ILiquidPool(_pools[i]).changeFeeDestinationAddress(
                _newFeeDestinationAddress[i]
            );

            emit FeeDestinatoinChanged(
                _pools[i],
                _newFeeDestinationAddress[i]
            );
        }
    }

    /**
     * @dev
     * Allows to withdraw accumulated fees
     * storing them in the router contract
     */
    function withdrawFees(
        address[] calldata _pools,
        uint256[] calldata _shares
    )
        external
    {
        for (uint32 i = 0; i < _pools.length; i++) {
            ILiquidPool(_pools[i]).withdrawFunds(
                _shares[i],
                address(this)
            );
        }
    }

    /**
     * @dev
     * Removes any tokens accumulated
     * by the router including fees
     */
    function removeToken(
        address _tokenAddress,
        address _depositAddress
    )
        external
        onlyMultisig
    {
        uint256 tokenBalance = _safeBalance(
            _tokenAddress,
            address(this)
        );

        _safeTransfer(
            _tokenAddress,
            _depositAddress,
            tokenBalance
        );
    }

    /**
     * @dev Determines info for the heartbeat update mechanism for chainlink
     * oracles (roundIds)
     */
    function getLatestAggregatorRoundId(
        address _feed
    )
        public
        view
        returns (uint80)
    {
        (   uint80 roundId,
            ,
            ,
            ,
        ) = IChainLink(_feed).latestRoundData();

        return uint64(roundId);
    }

    /**
     * @dev Determines info for the heartbeat update mechanism for chainlink
     * oracles (shifted round Ids)
     */
    function getRoundIdByByteShift(
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        public
        pure
        returns (uint80)
    {
        return uint80(uint256(_phaseId) << 64 | _aggregatorRoundId);
    }

    /**
     * @dev View function to determine the heartbeat to see if updating heartbeat
     * is necessary or not (compare to current value).
     * Looks at the maximal last 50 rounds and takes second highest value to
     * avoid counting offline time of chainlink as valid heartbeat
     */
    function recalibratePreview(
        address _feed
    )
        public
        view
        returns (uint256)
    {
        uint80 latestAggregatorRoundId = getLatestAggregatorRoundId(
            _feed
        );

        uint80 iterationCount = _getIterationCount(
            latestAggregatorRoundId
        );

        if (iterationCount < 2) {
            revert("LiquidRouter: SMALL_SAMPLE");
        }

        uint16 phaseId = IChainLink(_feed).phaseId();
        uint256 latestTimestamp = _getRoundTimestamp(
            _feed,
            phaseId,
            latestAggregatorRoundId
        );

        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        for (uint80 i = 1; i < iterationCount; i++) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _feed,
                phaseId,
                latestAggregatorRoundId - i
            );

            currentDiff = latestTimestamp
                - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {
                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;
            } else if (currentDiff > currentSecondBiggest && currentDiff < currentBiggest) {
                currentSecondBiggest = currentDiff;
            }
        }

        return currentSecondBiggest;
    }

    /**
     * @dev Determines number of iterations necessary during recalibrating
     * heartbeat.
     */
    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80)
    {
        return _latestAggregatorRoundId > MAX_ROUND_COUNT
            ? MAX_ROUND_COUNT
            : _latestAggregatorRoundId;
    }

    /**
     * @dev fetches timestamp of a byteshifted aggregatorRound with specific
     * phaseID. For more info see chainlink historical price data documentation
     */
    function _getRoundTimestamp(
        address _feed,
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp,
        ) = IChainLink(_feed).getRoundData(
            getRoundIdByByteShift(
                _phaseId,
                _aggregatorRoundId
            )
        );

        return timestamp;
    }

    /**
     * @dev Function to recalibrate the heartbeat for a specific feed
     */
    function recalibrate(
        address _feed
    )
        external
    {
        chainLinkHeartBeat[_feed] = recalibratePreview(_feed);
    }
}
