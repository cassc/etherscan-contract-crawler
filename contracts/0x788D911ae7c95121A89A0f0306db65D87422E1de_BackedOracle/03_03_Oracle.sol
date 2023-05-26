pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
  external
  view
  returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );

  function latestRoundData()
  external
  view
  returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );

}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

contract BackedOracle is AggregatorV2V3Interface, Ownable {
  struct RoundData {
    int192 answer;
    uint32 timestamp;
  }

  uint8 private _decimals;
  string private _description;

  mapping(uint256 => RoundData) private _roundData;
  uint80 private _latestRoundNumber;

  constructor(uint8 decimals, string memory description) {
    _decimals = decimals;
    _description = description;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function description() external view override returns (string memory) {
    return _description;
  }

  function latestAnswer() external view override returns (int256) {
    return _roundData[_latestRoundNumber].answer;
  }

  function latestTimestamp() external view override returns (uint256) {
    return _roundData[_latestRoundNumber].timestamp;
  }

  function latestRound() external view override returns (uint256) {
    return _latestRoundNumber;
  }

  function getAnswer(uint256 roundId) external view override returns (int256) {
    return _roundData[roundId].answer;
  }

  function getTimestamp(uint256 roundId) external view override returns (uint256) {
    return _roundData[roundId].timestamp;
  }

  function updateAnswer(int192 newAnswer, uint32 newTimestamp, uint32 newRound) public onlyOwner {
    _roundData[newRound] = RoundData(newAnswer, newTimestamp);
    _latestRoundNumber = newRound;

    emit AnswerUpdated(newAnswer, newRound, newTimestamp);
    emit NewRound(newRound, msg.sender, newTimestamp);
  }

  function getRoundData(uint80 roundId) external view override returns (
    uint80,
    int256,
    uint256,
    uint256,
    uint80
  ) {
    require(_roundData[roundId].answer != 0, "No data present");

    return (roundId, _roundData[roundId].answer, _roundData[roundId].timestamp, _roundData[roundId].timestamp, roundId);
  }

  function latestRoundData() external view override returns (
    uint80,
    int256,
    uint256,
    uint256,
    uint80
  ) {
    require(_latestRoundNumber != 0, "No data present");

    return (uint80(_latestRoundNumber), _roundData[_latestRoundNumber].answer, _roundData[_latestRoundNumber].timestamp, _roundData[_latestRoundNumber].timestamp, uint80(_latestRoundNumber));
  }
}