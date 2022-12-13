// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/AggregatorV2V3Interface.sol";
import "./AtlantisPriceOracleProxy.sol";
import "./AtlantisPriceOracleStorage.sol";

interface IAToken {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function underlying() external view returns (address);
}

interface IERC20 {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract AtlantisPriceOracle is AtlantisPriceOracleStorage {
    using SafeMath for uint256;

    event PricePosted(
        address asset,
        uint256 previousPriceMantissa,
        uint256 requestedPriceMantissa,
        uint256 newPriceMantissa
    );

    event FeedSet(OracleType oracleType, address feed, string symbol);

    constructor() {}

    function getUnderlyingPrice(address _aToken) external view returns (uint256 answer) {
        IAToken aToken = IAToken(_aToken);

        if (compareStrings(aToken.symbol(), "aBNB")) {
            return getOraclePrice("BNB");
        } else {
            return getPrice(aToken);
        }
    }

    function getPrice(IAToken aToken) internal view returns (uint256 price) {
        if (prices[address(aToken)] != 0) {
            price = prices[address(aToken)];
        } else {
            price = getOraclePrice(IERC20(aToken.underlying()).symbol());
        }

        uint256 decimalDelta = uint256(18).sub(uint256(IERC20(aToken.underlying()).decimals()));
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return price.mul(10 ** decimalDelta);
        } else {
            return price;
        }
    }

    function getOraclePrice(string memory symbol) public view returns (uint256 answer) {
        AggregatorV2V3Interface chainLinkFeed = getFeed(uint8(OracleType.CHAINLINK), symbol);
        AggregatorV2V3Interface binanceFeed = getFeed(uint8(OracleType.BINANCE), symbol);

        require(address(chainLinkFeed) != address(0) || address(binanceFeed) != address(0), "Feed not found");

        uint256 chainLinkLastAnswer = getLastAnswer(chainLinkFeed);
        uint256 binanceLastAnswer = getLastAnswer(binanceFeed);

        uint256[] memory answers = new uint256[](2);
        answers[0] = chainLinkLastAnswer;
        answers[1] = binanceLastAnswer;

        answer = calculateAvgPrice(answers);
    }


    function getLastAnswer(AggregatorV2V3Interface feed) internal view returns (uint256) {
        if (address(feed) == address(0)) {
            return 0;
        }

        // Oracle USD-denominated feeds store answers at 8 decimals
        uint decimalDelta = uint(18).sub(feed.decimals());

        try feed.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            // Ensure that we don't multiply the result by 0
            if (decimalDelta > 0) {
                return uint256(answer).mul(10 ** decimalDelta);
            } else {
                return uint256(answer);
            }
        } catch {
            return 0;
        }
    }

    function calculateAvgPrice(uint256[] memory _oraclePrices) internal pure returns (uint256 average) {
        uint256 sum;
        uint8 activeOracleLength;

        for (uint256 i; i < _oraclePrices.length; ++i) {
            if (_oraclePrices[i] > 0) {
                sum += _oraclePrices[i];
                activeOracleLength += 1;
            }
        }

        require(sum > 0 && activeOracleLength > 0, "Can't calculate average price");
        average = sum / activeOracleLength;
    }

    // function calculateDifference(uint256 amountOne, uint256 amountTwo) internal pure returns (int percentage) {
    //     percentage = ((int(amountOne) - int(amountTwo)) * 10_000) / int(amountOne) / 100;
    // }

    function getFeed(uint8 oracleType, string memory symbol) public view returns (AggregatorV2V3Interface) {
        return feeds[oracleType][keccak256(abi.encodePacked(symbol))];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }

    /*** Admin Functions ***/

    function setFeed(OracleType oracleType, string calldata symbol, address feed) external onlyAdmin {
        require(feed != address(0) && feed != address(this), "invalid feed address");

        feeds[uint8(oracleType)][keccak256(abi.encodePacked(symbol))] = AggregatorV2V3Interface(feed);
        emit FeedSet(oracleType, feed, symbol);
    }

    function setDirectPrice(IAToken aToken, uint256 price) external onlyAdmin {
        prices[address(aToken)] = price;
        emit PricePosted(address(aToken), prices[address(aToken)], price, price);
    }

    function _become(AtlantisPriceOracleProxy atlantisPriceOracleProxy) external {
        require(msg.sender == atlantisPriceOracleProxy.admin(), "only proxy admin can change brains");
        atlantisPriceOracleProxy._acceptImplementation();
    }
}