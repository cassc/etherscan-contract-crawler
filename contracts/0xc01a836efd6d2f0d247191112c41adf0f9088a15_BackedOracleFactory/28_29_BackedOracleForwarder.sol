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

import "@openzeppelin/contracts/access/Ownable.sol";

contract BackedOracleForwarder is Ownable, AggregatorV2V3Interface {
    AggregatorV2V3Interface public _upstreamOracle;

    constructor(address __upstreamOracle, address __owner) {
        _upstreamOracle = AggregatorV2V3Interface(__upstreamOracle);
        _transferOwnership(__owner);
    }

    function version() external view returns (uint256) {
        return _upstreamOracle.version();
    }

    function decimals() external view returns (uint8) {
        return _upstreamOracle.decimals();
    }

    function description() external view returns (string memory) {
        return _upstreamOracle.description();
    }

    function latestAnswer() external view returns (int256) {
        return _upstreamOracle.latestAnswer();
    }

    function latestTimestamp() external view returns (uint256) {
        return _upstreamOracle.latestTimestamp();
    }

    function latestRound() external view returns (uint256) {
        return _upstreamOracle.latestRound();
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return _upstreamOracle.latestRoundData();
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        return _upstreamOracle.getAnswer(roundId);
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        return _upstreamOracle.getTimestamp(roundId);
    }

    function getRoundData(
        uint80 roundId
    ) external view returns (uint80, int256, uint256, uint256, uint80) {
        return _upstreamOracle.getRoundData(roundId);
    }

    function setUpstreamOracle(address __upstreamOracle) external onlyOwner {
        _upstreamOracle = AggregatorV2V3Interface(__upstreamOracle);
    }
}