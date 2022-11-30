// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";
import "./LibMath.sol";
import "./LibAsset.sol";

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IChainlinkV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IChainlinkV2V3 is IChainlink, IChainlinkV3 {}

enum SpreadType {
    Ask,
    Bid
}

library LibReferenceOracle {
    using LibMath for uint256;
    using LibMath for uint96;
    using LibAsset for Asset;

    // indicate that the asset price is too far away from reference oracle
    event AssetPriceOutOfRange(uint8 assetId, uint96 price, uint96 referencePrice, uint32 deviation);

    /**
     * @dev Check oracle parameters before set.
     */
    function checkParameters(
        ReferenceOracleType referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation
    ) internal view {
        require(referenceDeviation <= 1e5, "D>1"); // %deviation > 100%
        if (referenceOracleType == ReferenceOracleType.Chainlink) {
            IChainlinkV2V3 o = IChainlinkV2V3(referenceOracle);
            require(o.decimals() == 8, "!D8"); // we only support decimals = 8
            require(o.latestAnswer() > 0, "P=0"); // oracle Price <= 0
        }
    }

    /**
     * @dev Truncate price if the error is too large.
     */
    function checkPrice(
        LiquidityPoolStorage storage pool,
        Asset storage asset,
        uint96 price
    ) internal returns (uint96) {
        require(price != 0, "P=0"); // broker price = 0

        // truncate price if the error is too large
        if (ReferenceOracleType(asset.referenceOracleType) == ReferenceOracleType.Chainlink) {
            uint96 ref = _readChainlink(asset.referenceOracle);
            price = _truncatePrice(asset, price, ref);
        }

        // strict stable dampener
        if (asset.isStrictStable()) {
            uint256 delta = price > 1e18 ? price - 1e18 : 1e18 - price;
            uint256 dampener = uint256(pool.strictStableDeviation) * 1e13; // 1e5 => 1e18
            if (delta <= dampener) {
                price = 1e18;
            }
        }

        return price;
    }

    /**
     * @dev check price and add spread, where spreadType should be:
     *
     *      subAccount.isLong   openPosition   closePosition   addLiquidity   removeLiquidity
     *      long                ask            bid
     *      short               bid            ask
     *      N/A                                                bid            ask
     */
    function checkPriceWithSpread(
        LiquidityPoolStorage storage pool,
        Asset storage asset,
        uint96 price,
        SpreadType spreadType
    ) internal returns (uint96) {
        price = checkPrice(pool, asset, price);
        price = _addSpread(asset, price, spreadType);
        return price;
    }

    function _readChainlink(address referenceOracle) internal view returns (uint96) {
        int256 ref = IChainlinkV2V3(referenceOracle).latestAnswer();
        require(ref > 0, "P=0"); // oracle Price <= 0
        ref *= 1e10; // decimals 8 => 18
        return uint256(ref).safeUint96();
    }

    function _truncatePrice(
        Asset storage asset,
        uint96 price,
        uint96 ref
    ) private returns (uint96) {
        if (asset.referenceDeviation == 0) {
            return ref;
        }
        uint256 deviation = uint256(ref).rmul(asset.referenceDeviation);
        uint96 bound = (uint256(ref) - deviation).safeUint96();
        if (price < bound) {
            emit AssetPriceOutOfRange(asset.id, price, ref, asset.referenceDeviation);
            price = bound;
        }
        bound = (uint256(ref) + deviation).safeUint96();
        if (price > bound) {
            emit AssetPriceOutOfRange(asset.id, price, ref, asset.referenceDeviation);
            price = bound;
        }
        return price;
    }

    function _addSpread(
        Asset storage asset,
        uint96 price,
        SpreadType spreadType
    ) private view returns (uint96) {
        if (asset.halfSpread == 0) {
            return price;
        }
        uint96 halfSpread = uint256(price).rmul(asset.halfSpread).safeUint96();
        if (spreadType == SpreadType.Bid) {
            require(price > halfSpread, "P=0"); // Price - halfSpread = 0. impossible
            return price - halfSpread;
        } else {
            return price + halfSpread;
        }
    }
}