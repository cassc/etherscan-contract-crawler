// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IFrxEthStableSwap.sol";
import "../interfaces/ISfrxEth.sol";

contract SfrxEthOracle is AggregatorV3Interface {
    using SafeCast for uint256;

    /// @notice The contract where rewards are accrued
    ISfrxEth public immutable staker;

    /// @notice The precision of staker pricePerShare, given as 10^decimals
    uint256 public immutable stakingPricePrecision;

    /// @notice Curve pool, source of TWAP for token
    IFrxEthStableSwap public immutable pool;

    /// @notice Chainlink aggregator
    AggregatorV3Interface public immutable chainlinkFeed;

    /// @notice Decimals of tokenA chainlink feed
    uint8 public immutable chainlinkFeedDecimals;

    /// @notice Is token1 of TWAP equal to target token for this oracle
    bool public immutable twapToken1IsToken;

    /// @notice Precision of twap oracle given as 10^decimals
    uint256 public immutable twapPrecision;

    /// @notice Maximum price of token1 in token0 units of the TWAP
    /// @dev Must match precision of TWAP
    uint256 public  immutable twapMax;

    /// @notice Description of oracle, follows chainlink convention
    string public description;

    /// @notice Decimals of precicion for price data
    uint8 public immutable decimals;

    /// @notice Name of Oracle
    string public name;

    /// @notice Version of Oracle
    uint256 public immutable version;

    constructor(
        address _stakingAddress,
        uint256 _stakingPricePrecision,
        address _poolAddress,
        address _chainlinkFeed,
        uint256 _twapMax,
        bool _twapToken1IsToken,
        uint256 _twapPrecision,
        string memory _description,
        uint8 _decimals,
        string memory _name,
        uint256 _version
    ) {
        staker = ISfrxEth(_stakingAddress);
        stakingPricePrecision = _stakingPricePrecision;
        pool = IFrxEthStableSwap(_poolAddress);
        chainlinkFeed = AggregatorV3Interface(_chainlinkFeed);
        chainlinkFeedDecimals = AggregatorV3Interface(_chainlinkFeed).decimals();
        twapToken1IsToken = _twapToken1IsToken;
        twapPrecision = _twapPrecision;
        twapMax = _twapMax;
        description = _description;
        decimals = _decimals;
        name = _name;
        version = _version;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        revert("getRoundData not implemented");
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 _tokenAPriceInt;
        (roundId, _tokenAPriceInt, startedAt, updatedAt, answeredInRound) = chainlinkFeed.latestRoundData();
        if (_tokenAPriceInt < 0) revert FeedPriceNegative();
        uint256 _tokenAPrice = uint256(_tokenAPriceInt);

        uint256 _twapMax = twapMax;
        // price oracle gives token1 price in terms of token0 units
        uint256 _oraclePrice = twapToken1IsToken
            ? pool.price_oracle()
            : (twapPrecision * twapPrecision) / pool.price_oracle();
        uint256 _tokenBPriceRelative = _oraclePrice > _twapMax ? _twapMax : _oraclePrice;

        uint256 _tokenCPriceInTokenB = staker.pricePerShare();

        uint256 _tokenAPriceScaled = _tokenAPrice * (10**decimals) / (10**chainlinkFeedDecimals);

        answer = ((_tokenCPriceInTokenB * _tokenBPriceRelative * _tokenAPriceScaled) / ( twapPrecision * stakingPricePrecision))
            .toInt256();
    }

    error FeedPriceNegative();
}