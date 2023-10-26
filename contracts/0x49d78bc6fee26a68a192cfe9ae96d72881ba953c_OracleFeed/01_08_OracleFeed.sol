// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/IAggregatorV3Interface.sol";

/**
 * @title OracleFeed
 */
contract OracleFeed is IAggregatorV3Interface, AccessControl {
    event AnswerUpdated(int256 indexed current, uint256 roundId, uint256 updatedAt);

    uint256 public constant version = 0;

    uint8 public override decimals;
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    string public description;


    constructor(uint8 _decimals, int256 _initialAnswer, string memory _description) {
        decimals = _decimals;
        description = _description;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        updateAnswer(_initialAnswer);
    }

    function updateAnswer(int256 _answer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        emit AnswerUpdated(latestAnswer, 0, block.timestamp);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(0),
            latestAnswer,
            latestTimestamp,
            latestTimestamp,
            uint80(0)
        );
    }
}