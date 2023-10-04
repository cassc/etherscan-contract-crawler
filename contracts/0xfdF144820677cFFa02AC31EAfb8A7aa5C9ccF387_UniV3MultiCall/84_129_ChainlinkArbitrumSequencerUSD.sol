// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "../../interfaces/oracles/chainlink/AggregatorV3Interface.sol";
import {ChainlinkBase} from "./ChainlinkBase.sol";
import {Constants} from "../../../Constants.sol";
import {Errors} from "../../../Errors.sol";

/**
 * @dev supports oracles which are compatible with v2v3 or v3 interfaces
 */
contract ChainlinkArbitrumSequencerUSD is ChainlinkBase {
    address internal constant SEQUENCER_FEED =
        0xFdB631F5EE196F0ed6FAa767959853A9F217697D; // arbitrum sequencer feed
    uint256 internal constant ARB_USD_BASE_CURRENCY_UNIT = 1e8; // 8 decimals for USD based oracles

    constructor(
        address[] memory _tokenAddrs,
        address[] memory _oracleAddrs
    ) ChainlinkBase(_tokenAddrs, _oracleAddrs, ARB_USD_BASE_CURRENCY_UNIT) {} // solhint-disable no-empty-blocks

    function _checkAndReturnLatestRoundData(
        address oracleAddr
    ) internal view override returns (uint256 tokenPriceRaw) {
        (, int256 answer, uint256 startedAt, , ) = AggregatorV3Interface(
            SEQUENCER_FEED
        ).latestRoundData();
        // check if sequencer is live
        if (answer != 0) {
            revert Errors.SequencerDown();
        }
        // check if last restart was less than or equal grace period length
        if (startedAt + Constants.SEQUENCER_GRACE_PERIOD > block.timestamp) {
            revert Errors.GracePeriodNotOver();
        }
        tokenPriceRaw = super._checkAndReturnLatestRoundData(oracleAddr);
    }
}