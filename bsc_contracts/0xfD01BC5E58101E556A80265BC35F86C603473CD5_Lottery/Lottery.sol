/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
  address public owner;
  address public winnerAddress;
  uint public eggs;
  uint public minerRewards;
  uint public lotteryRound;

  event LotteryWinner(address indexed investor, uint256 pot, uint256 miner, uint256 indexed round);

  function pickWinner(address _a, uint256 _pot, uint256 _miner) public {
    // Trigger the LotteryWinner event
    uint256 _round;
    _round += lotteryRound;
    emit LotteryWinner(_a, _pot, _miner, _round);
    // Increment the lottery round
    lotteryRound++;
  }
}