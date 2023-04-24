// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IPrizeDistributionBuffer.sol";
import "./interfaces/IDrawCalculator.sol";
import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IDrawBeacon.sol";
import "./interfaces/ITicket.sol";

import "../Constants.sol";

/**
 * @title  Asymetrix Protocol V1 DrawCalculator
 * @author Asymetrix Protocol Inc Team
 * @notice The DrawCalculator calculates the amount of user picks based on the
 *         user average weighted balance (during each draw period)
 */
contract DrawCalculator is Initializable, Constants, IDrawCalculator {
    /// @notice DrawBuffer address
    IDrawBuffer public drawBuffer;

    /// @notice Ticket associated with DrawCalculator
    ITicket public ticket;

    /// @notice The stored history of draw settings. Stored as ring buffer
    IPrizeDistributionBuffer public prizeDistributionBuffer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    function initialize(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) external virtual initializer {
        __DrawCalculator_init_unchained(
            _ticket,
            _drawBuffer,
            _prizeDistributionBuffer
        );
    }

    /// @notice Unchained initialization for DrawCalculator
    /// @param _ticket Ticket associated with this DrawCalculator
    /// @param _drawBuffer The address of the draw buffer to push draws to
    /// @param _prizeDistributionBuffer PrizeDistributionBuffer address
    function __DrawCalculator_init_unchained(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) internal onlyInitializing {
        require(
            address(_ticket) != address(0),
            "DrawCalculator/ticket-not-zero"
        );
        require(
            address(_prizeDistributionBuffer) != address(0),
            "DrawCalculator/pdb-not-zero"
        );
        require(
            address(_drawBuffer) != address(0),
            "DrawCalculator/dh-not-zero"
        );

        ticket = _ticket;
        drawBuffer = _drawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;

        emit Deployed(_ticket, _drawBuffer, _prizeDistributionBuffer);
    }

    /* ============ Public Functions ============ */

    /// @inheritdoc IDrawCalculator
    function getNormalizedBalancesForDrawIds(
        address _user,
        uint32[] calldata _drawIds
    ) external view override returns (uint256[] memory) {
        require(
            _drawIds.length <= MAX_DRAW_IDS_LENGTH,
            "DrawCalculator/wrong-array-length"
        );

        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        IPrizeDistributionBuffer.PrizeDistribution[]
            memory _prizeDistributions = prizeDistributionBuffer
                .getPrizeDistributions(_drawIds);

        return _getNormalizedBalancesAt(_user, _draws, _prizeDistributions);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawCalculator
    function calculateNumberOfUserPicks(
        address _user,
        uint32[] calldata _drawIds
    ) external view override returns (uint256[] memory) {
        require(
            _drawIds.length <= MAX_DRAW_IDS_LENGTH,
            "DrawCalculator/wrong-array-length"
        );

        /**
         * The userBalances are fractions representing their portion of the
         * liquidity for a draw.
         */
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        IPrizeDistributionBuffer.PrizeDistribution[]
            memory _prizeDistributions = prizeDistributionBuffer
                .getPrizeDistributions(_drawIds);
        uint256[] memory _normalizedUserBalances = _getNormalizedBalancesAt(
            _user,
            _draws,
            _prizeDistributions
        );
        uint256[] memory totaUserPicks = new uint256[](_drawIds.length);

        for (uint256 drawIndex = 0; drawIndex < _drawIds.length; ++drawIndex) {
            uint64 userPicks = _calculateNumberOfUserPicks(
                _prizeDistributions[drawIndex],
                _normalizedUserBalances[drawIndex]
            );

            totaUserPicks[drawIndex] = userPicks;
        }

        return totaUserPicks;
    }

    /// @inheritdoc IDrawCalculator
    function getDrawBuffer() external view override returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IDrawCalculator
    function getPrizeDistributionBuffer()
        external
        view
        override
        returns (IPrizeDistributionBuffer)
    {
        return prizeDistributionBuffer;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates the number of picks a user gets for a Draw,
     *         considering the normalized user balance and the PrizeDistribution.
     * @dev Divided by 1e18 since the normalized user balance is stored as a
     *      fixed point 18 number
     * @param _prizeDistribution The PrizeDistribution to consider
     * @param _normalizedUserBalance The normalized user balances to consider
     * @return The number of picks a user gets for a Draw
     */
    function _calculateNumberOfUserPicks(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint256 _normalizedUserBalance
    ) internal pure returns (uint64) {
        return
            uint64(
                (_normalizedUserBalance * _prizeDistribution.numberOfPicks) /
                    1 ether
            );
    }

    /**
     * @notice Calculates the normalized balance of a user against the total
     *         supply for timestamps
     * @param _user The user to consider
     * @param _draws The draws we are looking at
     * @param _prizeDistributions The distribution to consider (needed for draw
     *                            timestamp offsets)
     * @return An array of normalized balances
     */
    function _getNormalizedBalancesAt(
        address _user,
        IDrawBeacon.Draw[] memory _draws,
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory) {
        uint256 drawsLength = _draws.length;

        require(
            drawsLength == _prizeDistributions.length,
            "DrawCalculator/lengths-mismatch"
        );

        uint64[] memory _timestampsWithStartCutoffTimes = new uint64[](
            drawsLength
        );
        uint64[] memory _timestampsWithEndCutoffTimes = new uint64[](
            drawsLength
        );

        // Generate timestamps with draw cutoff offsets included
        for (uint32 i = 0; i < drawsLength; ++i) {
            unchecked {
                _timestampsWithStartCutoffTimes[i] =
                    _draws[i].timestamp -
                    _prizeDistributions[i].startTimestampOffset;

                _timestampsWithEndCutoffTimes[i] =
                    _draws[i].timestamp -
                    _prizeDistributions[i].endTimestampOffset;
            }
        }

        uint256[] memory balances = ticket.getAverageBalancesBetween(
            _user,
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory totalSupplies = ticket.getAverageTotalSuppliesBetween(
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory normalizedBalances = new uint256[](drawsLength);

        // Divide balances by total supplies (normalize)
        for (uint256 i = 0; i < drawsLength; ++i) {
            if (totalSupplies[i] == 0) {
                normalizedBalances[i] = 0;
            } else {
                normalizedBalances[i] =
                    (balances[i] * 1 ether) /
                    totalSupplies[i];
            }
        }

        return normalizedBalances;
    }
}