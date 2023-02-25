//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IOracle.sol';
import './Withdrawable.sol';

contract NFTOracleManager is Withdrawable {
    /// @notice chainlink aggregator oracle contract => support?
    mapping(address => bool) public supportOracles;

    /// @notice manager who can call this function to submit prices
    mapping(address => bool) public isManager;

    /// @notice updatable price range for the next round
    int public minChangeRate;
    int public maxChangeRate;

    /// @notice emitted when manager is set
    event ManagerSet(address manager, bool status);

    /// @notice emitted when updatable price range is set
    event RateSet(int256 min, int256 max);

    /// @notice emitted when oracles are set
    event OraclesSet(address[] oracleList, bool[] statusList);

    /// @notice emitted when prices are submitted
    event PricesSubmitted(address[] oracleList, int256[] prices, uint timestamp);

    constructor() {
        minChangeRate = 25; // 2.5%
        maxChangeRate = 300; // 30%
    }

    /// @notice set oracle contracts into nfts
    /// @param oracles array of chainlink aggregator contracts
    /// @param statusList array of bool status
    function setOracles(address[] memory oracles, bool[] memory statusList) external onlyOwner {
        require(oracles.length == statusList.length, 'setOracles: Invalid param length');

        for (uint index = 0; index < oracles.length; index++) {
            supportOracles[oracles[index]] = statusList[index];
        }

        emit OraclesSet(oracles, statusList);
    }

    /// @notice set manager who can call this contract to submit prices
    /// @param manager address of manager
    /// @param status bool status of the manager
    function setManager(address manager, bool status) external onlyOwner {
        isManager[manager] = status;

        emit ManagerSet(manager, status);
    }

    /// @notice set min and max rate for the price updatable range
    /// @param min % of min (100% == 1000)
    /// @param max % of max
    function setRate(int min, int max) external onlyOwner {
        require(min > 0 && min < 1000 && max > 0 && max < 1000, 'setRate: Invalid Param');

        minChangeRate = min;
        maxChangeRate = max;

        emit RateSet(minChangeRate, maxChangeRate);
    }

    /// @notice calculate the updatable price range for the next round
    /// @param oracle address of the chainlink oracle
    function getUpdateAvailablePriceRange(
        address oracle
    ) external view returns (bool isSupport, int256 minPrice, int256 maxPrice, uint256 nextRound) {
        int256 prevPrice = IOracle(oracle).latestAnswer();

        minPrice = (prevPrice * minChangeRate) / 1000;
        maxPrice = (prevPrice * maxChangeRate) / 1000;
        nextRound = IOracle(oracle).latestRound() + 1;
        isSupport = supportOracles[oracle];
    }

    /// @notice submit prices to chainlink aggregators
    /// @param oracles list of the chainlink oracle
    /// @param prices list of prices to submit
    function batchUpdate(address[] memory oracles, int256[] memory prices) public {
        require(isManager[msg.sender] || owner() == _msgSender(), 'batchUpdate: Not manager');
        require(oracles.length == prices.length, 'batchUpdate: Invalid param length');

        for (uint index = 0; index < oracles.length; index++) {
            address oracle = oracles[index];
            if (supportOracles[oracle]) {
                uint256 roundId = IOracle(oracle).latestRound();
                IOracle(oracle).submit(roundId + 1, prices[index]);
            }
        }

        emit PricesSubmitted(oracles, prices, block.timestamp);
    }
}