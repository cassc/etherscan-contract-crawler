/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2023 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity 0.8.9;

import "./BackedOracleInterface.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract BackedOracle is AccessControlUpgradeable, AggregatorV2V3Interface {
    uint8 public constant VERSION = 1;
    uint8 public constant MAX_PERCENT_DIFFERENCE = 10;
    uint32 public constant MAX_TIMESTAMP_AGE = 5 minutes;
    uint32 public constant MIN_UPDATE_INTERVAL = 1 hours;

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    struct RoundData {
        int192 answer;
        uint32 timestamp;
    }

    uint8 private _decimals;
    string private _description;

    mapping(uint256 => RoundData) private _roundData;
    uint80 private _latestRoundNumber;

    constructor() {
        initialize(0, "Backed Oracle Implementation", address(0), address(0));
    }

    function initialize(
        uint8 __decimals,
        string memory __description,

        address __admin,
        address __updater
    ) public initializer {
        _decimals = __decimals;
        _description = __description;

        _grantRole(DEFAULT_ADMIN_ROLE, __admin);
        _grantRole(UPDATER_ROLE, __updater);
    }

    function version() external view override returns (uint256) {
        return VERSION;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function latestAnswer() external view override returns (int256) {
        require(_latestRoundNumber != 0, "No data present");

        return _roundData[_latestRoundNumber].answer;
    }

    function latestTimestamp() external view override returns (uint256) {
        require(_latestRoundNumber != 0, "No data present");

        return _roundData[_latestRoundNumber].timestamp;
    }

    function latestRound() external view override returns (uint256) {
        require(_latestRoundNumber != 0, "No data present");

        return _latestRoundNumber;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        require(_latestRoundNumber != 0, "No data present");

        return (
            uint80(_latestRoundNumber),
            _roundData[_latestRoundNumber].answer,
            _roundData[_latestRoundNumber].timestamp,
            _roundData[_latestRoundNumber].timestamp,
            uint80(_latestRoundNumber)
        );
    }

    function getAnswer(
        uint256 roundId
    ) external view override returns (int256) {
        require(roundId <= _latestRoundNumber, "No data present");

        return _roundData[roundId].answer;
    }

    function getTimestamp(
        uint256 roundId
    ) external view override returns (uint256) {
        require(roundId <= _latestRoundNumber, "No data present");

        return _roundData[roundId].timestamp;
    }

    function getRoundData(
        uint80 roundId
    )
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        require(roundId <= _latestRoundNumber, "No data present");

        return (
            roundId,
            _roundData[roundId].answer,
            _roundData[roundId].timestamp,
            _roundData[roundId].timestamp,
            roundId
        );
    }

    function updateAnswer(
        int192 newAnswer,
        uint32 newTimestamp
    ) external onlyRole(UPDATER_ROLE) {
        int256 latestAnswer = _roundData[_latestRoundNumber].answer;
        uint256 latestTimestamp = _roundData[_latestRoundNumber].timestamp;

        // Timestamp is actual timestamp
        require(
            newTimestamp < block.timestamp,
            "Timestamp cannot be in the future"
        );

        // Check that the timestamp is not too old
        require(
            block.timestamp - newTimestamp <= MAX_TIMESTAMP_AGE,
            "Timestamp is too old"
        );

        // The timestamp is more than the last timestamp
        require(
            newTimestamp > latestTimestamp,
            "Timestamp is older than the last update"
        );

        // The last update happened more than MIN_UPDATE_INTERVAL ago
        require(
            newTimestamp - latestTimestamp > MIN_UPDATE_INTERVAL,
            "Timestamp cannot be updated too often"
        );

        // Limit the value to at most MAX_PERCENT_DIFFERENCE% different from the last value
        if (latestAnswer > 0) {
            int192 allowedDeviation = int192(
                (latestAnswer * int8(MAX_PERCENT_DIFFERENCE)) / 100
            );

            if (newAnswer > latestAnswer + allowedDeviation) {
                newAnswer = int192(latestAnswer + allowedDeviation);
            } else if (newAnswer < latestAnswer - allowedDeviation) {
                newAnswer = int192(latestAnswer - allowedDeviation);
            }
        }

        uint80 newRound = _latestRoundNumber + 1;

        _latestRoundNumber = newRound;
        _roundData[newRound] = RoundData(newAnswer, newTimestamp);

        emit AnswerUpdated(newAnswer, newRound, newTimestamp);
        emit NewRound(newRound, msg.sender, newTimestamp);
    }
}