//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

pragma experimental ABIEncoderV2;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "./AbstractAccumulator.sol";
import "../interfaces/ILiquidityAccumulator.sol";
import "../interfaces/ILiquidityOracle.sol";
import "../libraries/ObservationLibrary.sol";
import "../libraries/AddressLibrary.sol";
import "../utils/SimpleQuotationMetadata.sol";

abstract contract LiquidityAccumulator is
    IERC165,
    ILiquidityAccumulator,
    ILiquidityOracle,
    AbstractAccumulator,
    SimpleQuotationMetadata
{
    using AddressLibrary for address;
    using SafeCast for uint256;

    uint256 public immutable minUpdateDelay;
    uint256 public immutable maxUpdateDelay;

    mapping(address => AccumulationLibrary.LiquidityAccumulator) public accumulations;
    mapping(address => ObservationLibrary.LiquidityObservation) public observations;

    /**
     * @notice Emitted when the observed liquidities are validated against user (updater) provided liquidities.
     * @param token The token that the liquidity validation is for.
     * @param observedTokenLiquidity The observed token liquidity from the on-chain data source.
     * @param observedQuoteTokenLiquidity The observed quote token liquidity from the on-chain data source.
     * @param providedTokenLiquidity The token liquidity provided externally by the user (updater).
     * @param providedQuoteTokenLiquidity The quote token liquidity provided externally by the user (updater).
     * @param timestamp The timestamp of the block that the validation was performed in.
     * @param succeeded True if the observed liquidities closely matches the provided liquidities; false otherwise.
     */
    event ValidationPerformed(
        address indexed token,
        uint256 observedTokenLiquidity,
        uint256 observedQuoteTokenLiquidity,
        uint256 providedTokenLiquidity,
        uint256 providedQuoteTokenLiquidity,
        uint256 timestamp,
        bool succeeded
    );

    constructor(
        address quoteToken_,
        uint256 updateThreshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    ) AbstractAccumulator(updateThreshold_) SimpleQuotationMetadata(quoteToken_) {
        require(maxUpdateDelay_ >= minUpdateDelay_, "LiquidityAccumulator: INVALID_UPDATE_DELAYS");

        minUpdateDelay = minUpdateDelay_;
        maxUpdateDelay = maxUpdateDelay_;
    }

    /// @inheritdoc ILiquidityAccumulator
    function calculateLiquidity(
        AccumulationLibrary.LiquidityAccumulator calldata firstAccumulation,
        AccumulationLibrary.LiquidityAccumulator calldata secondAccumulation
    ) external pure virtual override returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        require(firstAccumulation.timestamp != 0, "LiquidityAccumulator: TIMESTAMP_CANNOT_BE_ZERO");

        uint32 deltaTime = secondAccumulation.timestamp - firstAccumulation.timestamp;
        require(deltaTime != 0, "LiquidityAccumulator: DELTA_TIME_CANNOT_BE_ZERO");

        unchecked {
            // Underflow is desired and results in correct functionality
            tokenLiquidity =
                (secondAccumulation.cumulativeTokenLiquidity - firstAccumulation.cumulativeTokenLiquidity) /
                deltaTime;
            quoteTokenLiquidity =
                (secondAccumulation.cumulativeQuoteTokenLiquidity - firstAccumulation.cumulativeQuoteTokenLiquidity) /
                deltaTime;
        }
    }

    /// @notice Determines whether the specified change threshold has been surpassed for the specified token.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param token The token to check.
    /// @param changeThreshold The change threshold as a percentage multiplied by the change precision
    ///   (`changePrecision`). Ex: a 1% change is respresented as 0.01 * `changePrecision`.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function changeThresholdSurpassed(address token, uint256 changeThreshold)
        public
        view
        virtual
        override
        returns (bool)
    {
        (uint256 tokenLiquidity, uint256 quoteTokenLiquidity) = fetchLiquidity(token);

        ObservationLibrary.LiquidityObservation storage lastObservation = observations[token];

        return
            changeThresholdSurpassed(tokenLiquidity, lastObservation.tokenLiquidity, changeThreshold) ||
            changeThresholdSurpassed(quoteTokenLiquidity, lastObservation.quoteTokenLiquidity, changeThreshold);
    }

    /// @notice Checks if this accumulator needs an update by checking the time since the last update and the change in
    ///   liquidities.
    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool) {
        uint256 deltaTime = timeSinceLastUpdate(data);
        if (deltaTime < minUpdateDelay) {
            // Ensures updates occur at most once every minUpdateDelay (seconds)
            return false;
        } else if (deltaTime >= maxUpdateDelay) {
            // Ensures updates occur (optimistically) at least once every maxUpdateDelay (seconds)
            return true;
        }

        /*
         * maxUpdateDelay > deltaTime >= minUpdateDelay
         *
         * Check if the % change in liquidity warrants an update (saves gas vs. always updating on change)
         */
        address token = abi.decode(data, (address));

        return updateThresholdSurpassed(token);
    }

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        return needsUpdate(data);
    }

    /// @notice Updates the accumulator for a specific token.
    /// @dev Must be called by an EOA to limit the attack vector, unless it's the first observation for a token.
    /// @param data Encoding of the token address followed by the expected token liquidity and quote token liquidity.
    /// @return updated True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual override returns (bool) {
        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return observations[token].timestamp;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    /// @inheritdoc ILiquidityAccumulator
    function getLastAccumulation(address token)
        public
        view
        virtual
        override
        returns (AccumulationLibrary.LiquidityAccumulator memory)
    {
        return accumulations[token];
    }

    /// @inheritdoc ILiquidityAccumulator
    function getCurrentAccumulation(address token)
        public
        view
        virtual
        override
        returns (AccumulationLibrary.LiquidityAccumulator memory accumulation)
    {
        ObservationLibrary.LiquidityObservation storage lastObservation = observations[token];
        require(lastObservation.timestamp != 0, "LiquidityAccumulator: UNINITIALIZED");

        accumulation = accumulations[token]; // Load last accumulation

        uint32 deltaTime = (block.timestamp - lastObservation.timestamp).toUint32();

        if (deltaTime != 0) {
            // The last observation liquidities have existed for some time, so we add that
            unchecked {
                // Overflow is desired and results in correct functionality
                // We add the liquidites multiplied by the time those liquidities were present
                accumulation.cumulativeTokenLiquidity += lastObservation.tokenLiquidity * deltaTime;
                accumulation.cumulativeQuoteTokenLiquidity += lastObservation.quoteTokenLiquidity * deltaTime;

                accumulation.timestamp = block.timestamp.toUint32();
            }
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, SimpleQuotationMetadata, AbstractAccumulator)
        returns (bool)
    {
        return
            interfaceId == type(ILiquidityAccumulator).interfaceId ||
            interfaceId == type(ILiquidityOracle).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            SimpleQuotationMetadata.supportsInterface(interfaceId) ||
            AbstractAccumulator.supportsInterface(interfaceId);
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(address token)
        public
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        if (token == quoteTokenAddress()) return (0, 0);

        ObservationLibrary.LiquidityObservation storage observation = observations[token];

        require(observation.timestamp != 0, "LiquidityAccumulator: MISSING_OBSERVATION");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @param maxAge The maximum age of the quotation, in seconds. If 0, fetches the real-time liquidity.
    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        if (token == quoteTokenAddress()) return (0, 0);

        if (maxAge == 0) return fetchLiquidity(token);

        ObservationLibrary.LiquidityObservation storage observation = observations[token];

        require(observation.timestamp != 0, "LiquidityAccumulator: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "LiquidityAccumulator: RATE_TOO_OLD");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    function performUpdate(bytes memory data) internal virtual returns (bool) {
        address token = abi.decode(data, (address));

        (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) = fetchLiquidity(token);

        // If the observation fails validation, do not update anything
        if (!validateObservation(data, tokenLiquidity, quoteTokenLiquidity)) return false;

        ObservationLibrary.LiquidityObservation storage observation = observations[token];
        AccumulationLibrary.LiquidityAccumulator storage accumulation = accumulations[token];

        if (observation.timestamp == 0) {
            /*
             * Initialize
             */
            observation.tokenLiquidity = accumulation.cumulativeTokenLiquidity = tokenLiquidity;
            observation.quoteTokenLiquidity = accumulation.cumulativeQuoteTokenLiquidity = quoteTokenLiquidity;
            observation.timestamp = accumulation.timestamp = block.timestamp.toUint32();

            emit Updated(token, tokenLiquidity, quoteTokenLiquidity, block.timestamp);

            return true;
        }

        /*
         * Update
         */

        uint32 deltaTime = (block.timestamp - observation.timestamp).toUint32();

        if (deltaTime != 0) {
            unchecked {
                // Overflow is desired and results in correct functionality
                // We add the liquidites multiplied by the time those liquidities were present
                accumulation.cumulativeTokenLiquidity += observation.tokenLiquidity * deltaTime;
                accumulation.cumulativeQuoteTokenLiquidity += observation.quoteTokenLiquidity * deltaTime;

                observation.tokenLiquidity = tokenLiquidity;
                observation.quoteTokenLiquidity = quoteTokenLiquidity;

                observation.timestamp = accumulation.timestamp = block.timestamp.toUint32();
            }

            emit Updated(token, tokenLiquidity, quoteTokenLiquidity, block.timestamp);

            return true;
        }

        return false;
    }

    /// @notice Requires the message sender of an update to not be a smart contract.
    /// @dev Can be overridden to disable this requirement.
    function validateObservationRequireEoa() internal virtual {
        // Message sender should never be a smart contract. Smart contracts can use flash attacks to manipulate data.
        require(msg.sender == tx.origin, "LiquidityAccumulator: MUST_BE_EOA");
    }

    function validateObservationAllowedChange(address) internal virtual returns (uint256) {
        // Allow the liquidity levels to change by half of the update threshold
        return updateThreshold / 2;
    }

    function validateObservation(
        bytes memory updateData,
        uint112 tokenLiquidity,
        uint112 quoteTokenLiquidity
    ) internal virtual returns (bool) {
        validateObservationRequireEoa();

        // Extract provided tokenLiquidity and quoteTokenLiquidity
        // The message sender should call consultLiquidity immediately before calling the update function, passing
        //   the returned values into the update data.
        (address token, uint112 pTokenLiquidity, uint112 pQuoteTokenLiquidity) = abi.decode(
            updateData,
            (address, uint112, uint112)
        );

        uint256 allowedChangeThreshold = validateObservationAllowedChange(token);

        // We require liquidity levels to not change by more than the threshold above
        // This check limits the ability of MEV and flashbots from manipulating data
        bool validated = !changeThresholdSurpassed(tokenLiquidity, pTokenLiquidity, allowedChangeThreshold) &&
            !changeThresholdSurpassed(quoteTokenLiquidity, pQuoteTokenLiquidity, allowedChangeThreshold);

        emit ValidationPerformed(
            token,
            tokenLiquidity,
            quoteTokenLiquidity,
            pTokenLiquidity,
            pQuoteTokenLiquidity,
            block.timestamp,
            validated
        );

        return validated;
    }

    function fetchLiquidity(address token)
        internal
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}