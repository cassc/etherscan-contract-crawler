// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface IChainLink {

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerdInRound
        );

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function phaseId()
        external
        view
        returns(
            uint16 phaseId
        );

    function aggregator()
        external
        view
        returns (address);
}
