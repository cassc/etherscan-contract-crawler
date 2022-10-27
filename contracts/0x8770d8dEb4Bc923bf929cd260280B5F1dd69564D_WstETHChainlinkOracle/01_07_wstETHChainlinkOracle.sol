// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {AggregatorV2V3Interface} from "AggregatorV2V3Interface.sol";
import {IWstETH} from "IWstETH.sol";
import {TypeConvert} from "TypeConvert.sol";

contract WstETHChainlinkOracle is AggregatorV2V3Interface {
    using TypeConvert for uint256;

    uint8 public override constant decimals = 18;
    uint256 public override constant version = 1;

    string public override description;
    AggregatorV2V3Interface public immutable baseOracle;
    int256 public immutable baseDecimals;
    IWstETH public immutable wstETH;

    constructor(AggregatorV2V3Interface baseOracle_, IWstETH wstETH_) {
        baseOracle = baseOracle_;
        wstETH = wstETH_;
        description = "wstETH Chainlink Oracle";
        baseDecimals = int256(10**baseOracle_.decimals());
    }

    function _calculateAnswer() internal view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        int256 baseAnswer;
        (
            roundId,
            baseAnswer,
            startedAt,
            updatedAt,
            answeredInRound
        ) = baseOracle.latestRoundData();
        require(baseAnswer > 0, "Chainlink Rate Error");

        answer = baseAnswer * wstETH.stEthPerToken().toInt() / baseDecimals;
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return _calculateAnswer();
    }

    function latestAnswer() external view override returns (int256 answer) {
        (/* */, answer, /* */, /* */, /* */) = _calculateAnswer();
    }

    function latestTimestamp() external view override returns (uint256 updatedAt) {
        (/* */, /* */, /* */, updatedAt, /* */) = _calculateAnswer();
    }

    function latestRound() external view override returns (uint256 roundId) {
        (roundId, /* */, /* */, /* */, /* */) = _calculateAnswer();
    }

    function getRoundData(uint80 _roundId) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        revert();
    }

    function getAnswer(uint256 roundId) external view override returns (int256) { revert(); }
    function getTimestamp(uint256 roundId) external view override returns (uint256) { revert(); }
}