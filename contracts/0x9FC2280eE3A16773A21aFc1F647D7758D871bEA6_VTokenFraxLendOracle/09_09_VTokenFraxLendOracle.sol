// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "../interfaces/external/vesper/IVesperPool.sol";

/**
 * @title Oracle for vPool token (FraxLend)
 */
contract VTokenFraxLendOracle {
    using SafeCast for int256;
    using SafeCast for uint256;

    IVesperPool public immutable vToken;
    AggregatorV3Interface public immutable aggregator;
    uint8 public immutable underlyingDecimals;

    constructor(AggregatorV3Interface aggregator_, IVesperPool vToken_) {
        aggregator = aggregator_;
        vToken = vToken_;
        underlyingDecimals = IERC20Metadata(vToken_.token()).decimals();
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        int256 _answer;
        (roundId, _answer, startedAt, updatedAt, answeredInRound) = aggregator.latestRoundData();
        answer = ((_answer.toUint256() * vToken.pricePerShare()) / 10**underlyingDecimals).toInt256();
    }
}