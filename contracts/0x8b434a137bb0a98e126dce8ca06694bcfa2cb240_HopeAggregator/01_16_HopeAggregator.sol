// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {IHopeAggregator} from '../interfaces/IHopeAggregator.sol';
import {HopeOneRole} from '../access/HopeOneRole.sol';

contract HopeAggregator is HopeOneRole, IHopeAggregator {
  uint256 public constant override version = 1;
  uint8 public immutable override decimals;
  string public override description; // 'HOPE/USD'
  uint80 internal roundId;

  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }
  mapping(uint80 /* aggregator round ID */ => Transmission) internal transmissions;

  constructor(uint8 _decimals, string memory _description) {
    decimals = _decimals;
    description = _description;
  }

  function transmit(uint256 _answer) external override onlyRole(OPERATOR_ROLE) {
    roundId++;
    int192 currentPrice = int192(int256(_answer));
    transmissions[roundId] = Transmission(currentPrice, uint64(block.timestamp));
    emit AnswerUpdated(currentPrice, roundId, uint64(block.timestamp));
  }

  function latestAnswer() external view override returns (int256) {
    return transmissions[roundId].answer;
  }

  function latestTimestamp() external view override returns (uint256) {
    return transmissions[roundId].timestamp;
  }

  function latestRound() external view override returns (uint256) {
    return roundId;
  }

  function getAnswer(uint256 _roundId) external view override returns (int256) {
    return transmissions[uint80(_roundId)].answer;
  }

  function getTimestamp(uint256 _roundId) external view override returns (uint256) {
    return transmissions[uint80(_roundId)].timestamp;
  }

  function getRoundData(uint80 _roundId) external view override returns (uint80, int256, uint256, uint256, uint80) {
    Transmission memory transmission = transmissions[_roundId];
    return (_roundId, transmission.answer, transmission.timestamp, transmission.timestamp, _roundId);
  }

  function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
    Transmission memory transmission = transmissions[roundId];
    return (roundId, transmission.answer, transmission.timestamp, transmission.timestamp, roundId);
  }
}