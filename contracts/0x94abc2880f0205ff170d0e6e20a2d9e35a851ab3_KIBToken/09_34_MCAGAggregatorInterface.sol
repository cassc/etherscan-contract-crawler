// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface MCAGAggregatorInterface {
    event AccessControllerSet(address accesController);
    event AnswerTransmitted(address indexed transmitter, uint80 roundId, int256 answer);
    event MaxAnswerSet(int256 oldMaxAnswer, int256 newMaxAnswer);
    event VolatilityThresholdSet(uint256 oldVolatilityThreshold, uint256 newVolatilityThreshold);
    event TermSet(uint256 term);

    function transmit(int256 answer) external;

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function maxAnswer() external view returns (int256);

    function getVolatilityThreshold() external view returns (uint256);

    function version() external view returns (uint8);

    function getTerm() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}