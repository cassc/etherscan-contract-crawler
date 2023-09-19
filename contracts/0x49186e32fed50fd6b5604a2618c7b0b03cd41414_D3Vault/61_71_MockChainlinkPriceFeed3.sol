// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockChainlinkPriceFeed3 is AggregatorV3Interface, Ownable {
    string public description;
    uint8 public decimals;
    uint256 public version = 1;
    int256 public price;
    uint80 public round;
    uint256 public startTime;
    uint256 public updateTime;

    constructor(string memory _description, uint8 _decimals) {
        description = _description;
        decimals = _decimals;
        startTime = block.timestamp;
    }

    function feedData(int256 _price) public {
        price = _price;
        round += 1;
        updateTime = block.timestamp;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        require(_roundId <= round, "wrong round id");
        roundId = _roundId;
        answer = price;
        startedAt = startTime;
        updatedAt = updateTime;
        answeredInRound = _roundId;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = round;
        answer = price;
        startedAt = startTime;
        updatedAt = updateTime;
        answeredInRound = round;
    }

    // Make forge coverage ignore
    function testSuccess() public {}
}