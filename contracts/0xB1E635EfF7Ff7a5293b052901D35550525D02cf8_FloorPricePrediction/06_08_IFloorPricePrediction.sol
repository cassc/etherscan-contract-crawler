// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFloorPricePrediction {
    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 bullAmount;
        uint256 bearAmount;
        bool houseWinClaimed;
    }

    struct RoundInfo {
        address market;
        uint256 intervalSeconds;
        uint256 epoch;
        uint256 lockPriceOracleId;
        uint256 closePriceOracleId;
    }

    struct Bet {
        bool isBear;
        bool claimed; // default false
        uint256 amount;
    }

    struct BetInfo {
        address market;
        uint256 intervalSeconds;
        uint256 lockIntervalSeconds;
        uint256 epoch;
        uint256 nth;
        uint256 lockPriceOracleId;
        uint256 closePriceOracleId;
    }

    struct Interval {
        uint256 intervalSeconds;
        uint256 lockIntervalSeconds;
    }

    struct OracleIds {
        uint256 lockPriceOracleId;
        uint256 closePriceOracleId;
    }

    struct Period {
        uint256 currentEpoch;
        uint256 intervalSeconds;
        uint256 genesisTimestamp;
        uint256 lockIntervalSeconds;
        mapping(uint256 => mapping(address => Bet[])) ledger;
        mapping(uint256 => Round) rounds;
    }

    struct Market {
        address nftContract;
        bool paused;
        mapping(uint256 => Period) periods; // intervalSeconds => Period
        Interval[] intervals;
    }

    struct PredictionParams {
        address _oracleAddress;
        address _adminAddress;
        uint256 _minBetAmount;
        uint256 _treasuryFee;
        uint256 _genesisTimestamp;
        address[] _nftContracts;
        Interval[] _intervals;
    }

    event NewBet(
        address indexed sender,
        uint256 amount,
        address indexed market,
        uint256 indexed intervalSeconds,
        uint256 lockIntervalSeconds,
        uint256 epoch,
        uint256 lockTimestamp,
        uint256 closeTimestamp,
        bool isBear,
        uint256 nth
    );
    event Claim(
        address indexed sender,
        uint256 indexed amount,
        address indexed market,
        uint256 period,
        uint256 epoch,
        uint256 nth
    );
    event TreasuryClaim(uint256 amount);
    event NewMinBetAmount(uint256 minBetAmount);
    event NewTreasuryFee(uint256 treasuryFee);
    event NewOracle(address oracle);
    event NewAdminAddress(address admin);
    event NewMarket(address market, Interval[] intervals, uint256 genesisTimestamps);
    event NewPeriodInMarket(address market, Interval[] intervals, uint256 genesisTimestamps);
    event MarketPause(address market);
    event MarketUnpause(address market);
}