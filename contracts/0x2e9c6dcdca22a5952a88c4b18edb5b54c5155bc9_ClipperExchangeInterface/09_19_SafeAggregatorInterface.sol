// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library SafeAggregatorInterface {
    using SafeCast for int256;

    uint256 constant ONE_DAY_IN_SECONDS = 86400;

    function safeUnsignedLatest(AggregatorV3Interface oracle) internal view returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = oracle.latestRoundData();
        require((roundId==answeredInRound) && (updatedAt+ONE_DAY_IN_SECONDS > block.timestamp), "Oracle out of date");
        return answer.toUint256();
    }
}