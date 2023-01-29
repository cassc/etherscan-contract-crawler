//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IGMUOracle, IPriceFeed} from "./interfaces/IGMUOracle.sol";
import {Epoch} from "./utils/Epoch.sol";
import {KeeperCompatibleInterface} from "./interfaces/KeeperCompatibleInterface.sol";

/**
 * This is the GMU oracle that algorithmically apprecaites ARTH based on the
 * growth of the underlying.
 *
 * @author Steven Enamakel [email protected]
 */
contract GMUOracle is IGMUOracle, Epoch, KeeperCompatibleInterface {
    using SafeMath for uint256;

    /**
     * @dev last captured price from the 7 day oracle
     */
    uint256 public lastPrice7d;

    /**
     * @dev last captured price from the 30 day oracle
     */
    uint256 public lastPrice30d;

    /**
     * @dev max price the gmu can change by per epoch; if this gets hit then
     * the oracle breaks and the protocol will have to restart using a new oracle.
     */
    uint256 public constant MAX_PRICE_CHANGE = 50 * 1e16;

    /**
     * @dev has the oracle been broken? If there was a large price change
     * in the target price then the oracle breaks reverting and stopping
     * the protocol.
     *
     * The only way for the protocol to continue operations is to use a new oracle
     * and disregard this one.
     */
    bool public broken;

    /**
     * @dev the trusted oracle providing the ETH/USD pricefeed
     */
    IPriceFeed public immutable oracle;

    /**
     * @dev a dampening factor that dampens the appreciation of ARTH whenever ETH
     * appreciates. This is ideally set at 10%;
     */
    uint256 public constant DAMPENING_FACTOR = 10 * 1e18;

    /**
     * @dev track the historic prices captured from the oracle
     */
    mapping(uint256 => uint256) public priceHistory;

    /**
     * @dev last known index of the priceHistory
     */
    uint256 public lastPriceIndex;

    uint256 public cummulativePrice30d;
    uint256 public cummulativePrice7d;

    uint256 internal _startPrice;
    uint256 internal _endPrice;
    uint256 internal _endPriceTime;
    uint256 internal _startPriceTime;
    uint256 internal _priceDiff;
    uint256 internal _timeDiff;

    constructor(
        uint256 _startingPrice18,
        address _oracle,
        uint256[] memory _priceHistory30d
    ) Epoch(86400, block.timestamp, 0) {
        _startPrice = _startingPrice18;
        _endPrice = _startingPrice18;
        _endPriceTime = block.timestamp;
        _startPriceTime = block.timestamp;

        for (uint256 index = 0; index < 30; index++) {
            priceHistory[index] = _priceHistory30d[index];
            cummulativePrice30d += _priceHistory30d[index];
            if (index >= 23) cummulativePrice7d += _priceHistory30d[index];
        }

        lastPriceIndex = 30;
        lastPrice30d = cummulativePrice30d / 30;
        lastPrice7d = cummulativePrice7d / 7;

        oracle = IPriceFeed(_oracle);

        renounceOwnership();
    }

    function fetchPrice() external override returns (uint256) {
        require(!broken, "oracle is broken"); // failsafe check
        if (_callable()) _updatePrice(); // update oracle if needed
        return _fetchPriceAt(block.timestamp);
    }

    function fetchPriceAt(uint256 time) external returns (uint256) {
        require(!broken, "oracle is broken"); // failsafe check
        if (_callable()) _updatePrice(); // update oracle if needed
        return _fetchPriceAt(time);
    }

    function fetchLastGoodPrice() external view override returns (uint256) {
        return _fetchPriceAt(block.timestamp);
    }

    function fetchLastGoodPriceAt(uint256 time)
        external
        view
        returns (uint256)
    {
        return _fetchPriceAt(time);
    }

    function _fetchPriceAt(uint256 time) internal view returns (uint256) {
        if (_startPriceTime >= time) return _startPrice;
        if (_endPriceTime <= time) return _endPrice;

        uint256 percentage = (time.sub(_startPriceTime)).mul(1e24).div(
            _timeDiff
        );

        return _startPrice + _priceDiff.mul(percentage).div(1e24);
    }

    function _notifyNewPrice(uint256 newPrice, uint256 extraTime) internal {
        require(extraTime > 0, "bad time");

        _startPrice = _fetchPriceAt(block.timestamp);
        require(newPrice > _startPrice, "bad price");

        _endPrice = newPrice;
        _endPriceTime = block.timestamp + extraTime;
        _startPriceTime = block.timestamp;

        _priceDiff = _endPrice.sub(_startPrice);
        _timeDiff = _endPriceTime.sub(_startPriceTime);
    }

    function updatePrice() external override {
        _updatePrice();
    }

    function _updatePrice() internal checkEpoch {
        // record the new price point
        priceHistory[lastPriceIndex] = oracle.fetchPrice();

        // update the 30d TWAP
        cummulativePrice30d =
            cummulativePrice30d +
            priceHistory[lastPriceIndex] -
            priceHistory[lastPriceIndex - 30];

        // update the 7d TWAP
        cummulativePrice7d =
            cummulativePrice7d +
            priceHistory[lastPriceIndex] -
            priceHistory[lastPriceIndex - 7];

        lastPriceIndex += 1;

        // calculate the TWAP prices
        uint256 price30d = cummulativePrice30d / 30;
        uint256 price7d = cummulativePrice7d / 7;

        // If we are going to change the price, check if both the 30d and 7d price are
        // appreciating
        if (price30d > lastPrice30d && price7d > lastPrice7d) {
            // Calculate for appreciation using the 30d price feed
            uint256 delta = price30d.sub(lastPrice30d);

            // % of change in e18 from 0-1
            uint256 priceChange18 = delta.mul(1e18).div(lastPrice30d);

            if (priceChange18 > MAX_PRICE_CHANGE) {
                // dont change the price and break the oracle
                broken = true;
                return;
            }

            // Appreciate the price by the same %. Since this is an addition; the price
            // can only go up.
            uint256 newPrice = _endPrice +
                _endPrice
                    .mul(priceChange18)
                    .div(1e18)
                    .mul(DAMPENING_FACTOR)
                    .div(1e20);

            _notifyNewPrice(newPrice, 86400);
            emit LastGoodPriceUpdated(newPrice);
        }

        // Update the TWAP price trackers
        lastPrice7d = price7d;
        lastPrice30d = price30d;

        emit PricesUpdated(
            msg.sender,
            price30d,
            price7d,
            lastPriceIndex,
            _endPrice
        );
    }

    function getDecimalPercision() external pure override returns (uint256) {
        return 18;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool, bytes memory)
    {
        if (_callable()) return (true, "");
        return (false, "");
    }

    function performUpkeep(bytes calldata) external override {
        _updatePrice();
    }
}