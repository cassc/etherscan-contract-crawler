// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IPrizeDistributionBuffer.sol";

import "./libraries/DrawRingBufferLib.sol";

import "../owner-manager/Manageable.sol";

import "../Constants.sol";

/**
 * @title  Asymetrix Protocol V1 PrizeDistributionBuffer
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributionBuffer contract provides historical lookups of
 *         PrizeDistribution struct parameters (linked with a Draw ID) via a
 *          circular ring buffer. Historical PrizeDistribution parameters can be
 *          accessed on-chain using a drawId to calculate ring buffer storage
 *          slot. The PrizeDistribution parameters can be created by
 *          manager/owner and existing PrizeDistribution parameters can only be
 *          updated the owner. When adding a new PrizeDistribution basic sanity
 *          checks will be used to validate the incoming parameters.
 */
contract PrizeDistributionBuffer is
    Initializable,
    Constants,
    IPrizeDistributionBuffer,
    Manageable
{
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    /// @notice The maximum cardinality of the prize distribution ring buffer.
    /// @dev even with daily draws, 256 will give us over 8 months of history.
    uint256 internal constant MAX_CARDINALITY = 256;

    /// @notice Emitted when the contract is deployed.
    /// @param cardinality The maximum number of records in the buffer before
    ///                    they begin to expire.
    event Deployed(uint8 cardinality);

    /// @notice PrizeDistribution ring buffer history.
    IPrizeDistributionBuffer.PrizeDistribution[MAX_CARDINALITY]
        internal prizeDistributionRingBuffer;

    /// @notice Ring buffer metadata (nextIndex, lastId, cardinality)
    DrawRingBufferLib.Buffer internal bufferMetadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Initialize for PrizeDistributionBuffer
     * @param _owner Address of the PrizeDistributionBuffer owner
     * @param _cardinality Cardinality of the `bufferMetadata`
     */

    function initialize(
        address _owner,
        uint8 _cardinality
    ) external initializer {
        __Manageable_init_unchained(_owner);

        bufferMetadata.cardinality = _cardinality;

        emit Deployed(_cardinality);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributionBuffer
    function getBufferCardinality() external view override returns (uint32) {
        return bufferMetadata.cardinality;
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getPrizeDistribution(
        uint32 _drawId
    )
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _getPrizeDistribution(bufferMetadata, _drawId);
    }

    /// @inheritdoc IPrizeDistributionSource
    function getPrizeDistributions(
        uint32[] calldata _drawIds
    )
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution[] memory)
    {
        require(
            _drawIds.length <= MAX_DRAW_IDS_LENGTH,
            "PrizeDistributionBuffer/wrong-array-length"
        );

        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        IPrizeDistributionBuffer.PrizeDistribution[]
            memory _prizeDistributions = new IPrizeDistributionBuffer.PrizeDistribution[](
                _drawIds.length
            );

        for (uint256 i = 0; i < _drawIds.length; ++i) {
            _prizeDistributions[i] = _getPrizeDistribution(buffer, _drawIds[i]);
        }

        return _prizeDistributions;
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getPrizeDistributionCount()
        external
        view
        override
        returns (uint32)
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        if (buffer.lastDrawId == 0) {
            return 0;
        }

        uint32 bufferNextIndex = buffer.nextIndex;

        // If the buffer is full return the cardinality, else retun the nextIndex
        if (prizeDistributionRingBuffer[bufferNextIndex].numberOfPicks != 0) {
            return buffer.cardinality;
        } else {
            return bufferNextIndex;
        }
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getNewestPrizeDistribution()
        external
        view
        override
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        )
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        return (
            prizeDistributionRingBuffer[buffer.getIndex(buffer.lastDrawId)],
            buffer.lastDrawId
        );
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getOldestPrizeDistribution()
        external
        view
        override
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        )
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        // If the ring buffer is full, the oldest is at the nextIndex
        prizeDistribution = prizeDistributionRingBuffer[buffer.nextIndex];

        // The PrizeDistribution at index 0 Is by default the oldest
        // prizeDistribution.
        if (buffer.lastDrawId == 0) {
            // Return 0 to indicate no prizeDistribution ring bufferhistory
            drawId = 0;
        } else if (prizeDistribution.numberOfPicks == 0) {
            // If the next PrizeDistribution.numberOfPicks == 0 the ring buffer
            // has not looped around so the oldest is the first entry.
            prizeDistribution = prizeDistributionRingBuffer[0];
            drawId = (buffer.lastDrawId + 1) - buffer.nextIndex;
        } else {
            // Calculates the drawId using the ring buffer cardinality
            // Sequential drawIds are gauranteed by DrawRingBufferLib.push()
            drawId = (buffer.lastDrawId + 1) - buffer.cardinality;
        }
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function pushPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) external override onlyManagerOrOwner returns (bool) {
        return _pushPrizeDistribution(_drawId, _prizeDistribution);
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function setPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) external override onlyOwner returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        uint32 index = buffer.getIndex(_drawId);

        prizeDistributionRingBuffer[index] = _prizeDistribution;

        emit PrizeDistributionSet(_drawId, _prizeDistribution);

        return _drawId;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Gets the PrizeDistributionBuffer for a drawId
     * @param _buffer DrawRingBufferLib.Buffer
     * @param _drawId drawId
     */
    function _getPrizeDistribution(
        DrawRingBufferLib.Buffer memory _buffer,
        uint32 _drawId
    )
        internal
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return prizeDistributionRingBuffer[_buffer.getIndex(_drawId)];
    }

    /**
     * @notice Set newest PrizeDistributionBuffer in ring buffer storage.
     * @param _drawId draw ID
     * @param _prizeDistribution PrizeDistributionBuffer struct
     * @return `true` if operation is successful.
     */
    function _pushPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) internal returns (bool) {
        require(_drawId > 0, "PrizeDistributionBuffer/draw-id-gt-0");

        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        // Store the PrizeDistribution in the ring buffer
        prizeDistributionRingBuffer[buffer.nextIndex] = _prizeDistribution;

        // Update the ring buffer data
        bufferMetadata = buffer.push(_drawId);

        emit PrizeDistributionSet(_drawId, _prizeDistribution);

        return true;
    }
}