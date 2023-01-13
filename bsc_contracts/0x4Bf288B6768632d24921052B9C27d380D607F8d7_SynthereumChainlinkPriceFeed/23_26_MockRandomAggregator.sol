// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {SafeMath} from '../../@openzeppelin/contracts/utils/math/SafeMath.sol';
import {
  SignedSafeMath
} from '../../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import {Ownable} from '../../@openzeppelin/contracts/access/Ownable.sol';
import {MockAggregator} from './MockAggregator.sol';

contract MockRandomAggregator is Ownable, MockAggregator {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  uint256 public maxSpreadForSecond;

  constructor(int256 _initialAnswer, uint256 _maxSpreadForSecond)
    MockAggregator(18, _initialAnswer)
  {
    maxSpreadForSecond = _maxSpreadForSecond;
  }

  function latestRoundData()
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint256 randomNumber = getRandomNumber();
    answer = calculateNewPrice(randomNumber);
    (roundId, , startedAt, updatedAt, answeredInRound) = super
      .latestRoundData();
  }

  function updateAnswer(int256 _answer) public override onlyOwner {
    super.updateAnswer(_answer);
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public override onlyOwner {
    super.updateRoundData(_roundId, _answer, _timestamp, _startedAt);
  }

  function calculateNewPrice(uint256 randomNumber)
    internal
    view
    returns (int256 newPrice)
  {
    int256 lastPrice = latestAnswer;
    int256 difference =
      lastPrice
        .mul(int256(block.timestamp.sub(latestTimestamp)))
        .mul(int256(maxSpreadForSecond))
        .div(10**18)
        .mul(int256(randomNumber))
        .div(10**18);
    newPrice = (randomNumber.mod(2) == 0)
      ? latestAnswer.sub(difference)
      : latestAnswer.add(difference);
  }

  function getRandomNumber() internal view returns (uint256) {
    return uint256(blockhash(block.number - 1)).mod(10**18);
  }
}