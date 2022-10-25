//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILottery {
    function receiveRandomNumber(uint256 _lotteryId, uint256 _randomNumber)
        external;
}