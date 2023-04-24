// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../core/interfaces/IPrizeDistributionBuffer.sol";
import "../core/interfaces/IPrizeDistributionSource.sol";
import "../core/interfaces/IDrawBuffer.sol";
import "../core/interfaces/ITicket.sol";

import "../owner-manager/Manageable.sol";

/**
 * @title Prize Distribution Factory
 * @author Asymetrix Protocol Inc.
 * @notice The Prize Distribution Factory populates a Prize Distribution Buffer
 *         for a prize pool. It uses Draw Buffer and Ticket.
 */
contract PrizeDistributionFactory is Initializable, Manageable {
    using ExtendedSafeCastLib for uint256;

    /// @notice Emitted when a new Prize Distribution is pushed.
    /// @param drawId The draw ID for which the prize dist was pushed.
    /// @param totalNetworkTicketSupply The total network ticket supply that was
    ///                                 used to compute the number of picks.
    event PrizeDistributionPushed(
        uint32 indexed drawId,
        uint256 totalNetworkTicketSupply
    );

    /// @notice Emitted when a Prize Distribution is set (overrides another).
    /// @param drawId The draw ID for which the prize dist was set.
    event PrizeDistributionSet(uint32 indexed drawId);

    /**
     * @notice Emitted when a minimum pick cost is set (overrides another).
     * @param minPickCost The new minimum pick cost.
     */
    event MinPickCostSet(uint256 minPickCost);

    /**
     * @notice Emitted when the end timestamp offset is set.
     * @param endTimestampOffset The new endTimestampOffset.
     */
    event SetEndTimestampOffset(uint256 endTimestampOffset);

    /// @notice The draw buffer to pull the draw from.
    IDrawBuffer public drawBuffer;

    /// @notice The prize distribution buffer to push and set. This contract
    ///         must be the manager or owner of the buffer.
    IPrizeDistributionBuffer public prizeDistributionBuffer;

    /// @notice The draw beacon to pull the draw configuration data.
    IDrawBeacon public drawBeacon;

    /// @notice The ticket whose average total supply will be measured to
    ///         calculate the portion of picks.
    ITicket public ticket;

    /// @notice The minimum cost of each pick.
    uint256 public minPickCost;

    /// @notice The offset that is added on the end of the draw.
    uint32 public endTimestampOffset;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        IDrawBeacon _drawBeacon,
        ITicket _ticket,
        uint256 _minPickCost,
        uint32 _endTimestampOffset
    ) external initializer {
        __Manageable_init_unchained(_owner);

        require(_owner != address(0), "PDC/owner-zero");
        require(address(_drawBuffer) != address(0), "PDC/db-zero");
        require(
            address(_prizeDistributionBuffer) != address(0),
            "PDC/pdb-zero"
        );
        require(address(_drawBeacon) != address(0), "PDC/drawBeacon-zero");
        require(address(_ticket) != address(0), "PDC/ticket-zero");
        require(_minPickCost > 0, "PDC/pick-cost-gt-zero");

        minPickCost = _minPickCost;
        drawBuffer = _drawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;
        drawBeacon = _drawBeacon;
        ticket = _ticket;
        endTimestampOffset = _endTimestampOffset;
    }

    /**
     * @notice Allows the owner or manager to push a new prize distribution
     *         onto the buffer. The Draw for the given draw ID will be pulled
     *         in, and the total network ticket supply will be used to calculate
     *         number of picks.
     * @param _drawId The draw ID to compute for.
     * @param _totalNetworkTicketSupply The total supply of tickets across all
     *                                  prize pools for the network that the
     *                                  ticket belongs to.
     * @return The resulting Prize Distribution.
     */
    function pushPrizeDistribution(
        uint32 _drawId,
        uint256 _totalNetworkTicketSupply
    )
        external
        onlyManagerOrOwner
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeDistributionBuffer.PrizeDistribution
            memory prizeDistribution = calculatePrizeDistribution(_drawId);

        bool _pushed = prizeDistributionBuffer.pushPrizeDistribution(
            _drawId,
            prizeDistribution
        );

        require(_pushed, "PDC/prize-distribution-is-not-pushed");

        emit PrizeDistributionPushed(_drawId, _totalNetworkTicketSupply);

        return prizeDistribution;
    }

    /**
     * @notice Allows the owner to override an existing prize distribution in
     *         the buffer. The Draw for the given draw ID will be pulled in, and
     *         the total network ticket supply will be used to calculate the
     *         number of picks.
     * @param _drawId The draw ID to compute for, and that will be overwritten.
     * @return The resulting Prize Distribution.
     */
    function setPrizeDistribution(
        uint32 _drawId
    )
        external
        onlyOwner
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IPrizeDistributionBuffer.PrizeDistribution
            memory prizeDistribution = calculatePrizeDistribution(_drawId);
        prizeDistributionBuffer.setPrizeDistribution(
            _drawId,
            prizeDistribution
        );

        emit PrizeDistributionSet(_drawId);

        return prizeDistribution;
    }

    /**
     * @notice Allows the owner to override the minimum pick cost. The minimum
     *         pick cost will affect the amount of picks that each user gets.
     * @param _minPickCost The minimum amount of TWAB balance to get 1 pick.
     */
    function setMinPickCost(uint256 _minPickCost) external onlyOwner {
        require(_minPickCost > 0, "PDC/pick-cost-gt-zero");

        minPickCost = _minPickCost;

        emit MinPickCostSet(minPickCost);
    }

    /**
     * @notice Allows the owner to override the end timestamps offset.
     * @param _endTimestampOffset The new timestamps offset to set for future
     *                            prize distributions.
     */
    function setEndTimestampOffset(
        uint32 _endTimestampOffset
    ) external onlyOwner {
        endTimestampOffset = _endTimestampOffset;

        emit SetEndTimestampOffset(_endTimestampOffset);
    }

    /**
     * @notice Allows to estimate the picks that a user has from the total picks.
     * @param _user The user used to estimate the partial picks amount.
     * @return userPicks Partial amount of picks that a user has in the active
     *                   draw.
     * @return totalPicks Partial amount of total picks supply in the active
     *                    draw.
     */
    function estimatePartialPicks(
        address _user
    ) external view returns (uint256 userPicks, uint256 totalPicks) {
        uint64 currrentTime = uint64(block.timestamp);
        uint32 beaconPeriodSeconds = drawBeacon.getBeaconPeriodSeconds();
        uint64 beaconPeriodStartedAt = drawBeacon.getBeaconPeriodStartedAt();

        uint64[] memory startTimestamps = new uint64[](1);
        uint64[] memory endTimestamps = new uint64[](1);

        if (currrentTime - beaconPeriodSeconds > beaconPeriodStartedAt) {
            startTimestamps[0] = currrentTime - beaconPeriodSeconds;
        } else {
            startTimestamps[0] = beaconPeriodStartedAt;
        }

        endTimestamps[0] =
            startTimestamps[0] +
            beaconPeriodSeconds -
            endTimestampOffset;

        uint256[] memory totalSupplies = ticket.getAverageTotalSuppliesBetween(
            startTimestamps,
            endTimestamps
        );

        totalPicks = totalSupplies[0] / minPickCost;

        uint256[] memory balances = ticket.getAverageBalancesBetween(
            _user,
            startTimestamps,
            endTimestamps
        );

        if (totalSupplies[0] != 0) {
            uint256 normalizedBalance = (balances[0] * 1 ether) /
                totalSupplies[0];

            userPicks = uint64((normalizedBalance * totalPicks) / 1 ether);
        } else {
            userPicks = 0;
        }
    }

    /**
     * @notice Calculates what the prize distribution will be, given a draw ID
     *         and total network ticket supply.
     * @param _drawId The draw ID to pull from the Draw Buffer.
     * @return PrizeDistribution The result will include startTimestampOffset,
     *         endTimestampOffset, numberOfPicks.
     */
    function calculatePrizeDistribution(
        uint32 _drawId
    )
        public
        view
        virtual
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        IDrawBeacon.Draw memory draw = drawBuffer.getDraw(_drawId);

        return
            calculatePrizeDistributionWithDrawData(
                draw.beaconPeriodSeconds,
                draw.timestamp
            );
    }

    /**
     * @notice Calculates what the prize distribution will be, given a draw
     *         timestamp and the beacon period.
     * @param _beaconPeriodSeconds The beacon period in seconds.
     * @param _drawTimestamp The timestamp at which the draw started.
     * @return PrizeDistribution The calculated prize distributed based on the
     *         given params for the passed draw ID.
     */
    function calculatePrizeDistributionWithDrawData(
        uint32 _beaconPeriodSeconds,
        uint64 _drawTimestamp
    )
        public
        view
        virtual
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        uint64[] memory startTimestamps = new uint64[](1);
        uint64[] memory endTimestamps = new uint64[](1);
        uint32 _endTimestampOffset = endTimestampOffset;

        startTimestamps[0] = _drawTimestamp - _beaconPeriodSeconds;
        endTimestamps[0] = _drawTimestamp - _endTimestampOffset;

        uint256[] memory ticketAverageTotalSupplies = ticket
            .getAverageTotalSuppliesBetween(startTimestamps, endTimestamps);
        uint256 totalPicks = ticketAverageTotalSupplies[0] / minPickCost;

        IPrizeDistributionBuffer.PrizeDistribution
            memory prizeDistribution = IPrizeDistributionSource
                .PrizeDistribution({
                    startTimestampOffset: _beaconPeriodSeconds,
                    endTimestampOffset: _endTimestampOffset,
                    numberOfPicks: uint104(totalPicks)
                });

        return prizeDistribution;
    }
}