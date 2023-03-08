// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.10;

import {AggregatorInterface} from 'aave-v3-core/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {SafeCast} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/SafeCast.sol';

interface PotLike {
    function chi() external view returns (uint256);
}

/**
 * @title Savings Dai Oracle
 * @notice Convert DAI price to Savings DAI Price via the Pot.
 */
contract SavingsDaiOracle is AggregatorInterface {
    using SafeCast for uint256;

    int256 private constant RAY = 10 ** 27;

    AggregatorInterface internal _daiPriceFeed;
    PotLike internal _pot;

    constructor(AggregatorInterface daiPriceFeed, address pot) {
        _daiPriceFeed = daiPriceFeed;
        _pot = PotLike(pot);
    }

    function latestAnswer() external view returns (int256) {
        return _daiPriceFeed.latestAnswer() * _pot.chi().toInt256() / RAY;
    }

    function latestTimestamp() external view returns (uint256) {
        return _daiPriceFeed.latestTimestamp();
    }

    function latestRound() external view returns (uint256) {
        return _daiPriceFeed.latestRound();
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        return _daiPriceFeed.getAnswer(roundId) * _pot.chi().toInt256() / RAY;
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        return _daiPriceFeed.getTimestamp(roundId);
    }

    function DAI_PRICE_FEED_ADDRESS() external view returns (address) {
        return address(_daiPriceFeed);
    }

    function POT_ADDRESS() external view returns (address) {
        return address(_pot);
    }

}