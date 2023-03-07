pragma solidity ^0.8.0;

interface IWeeklyLottery {
    function addParticipant(uint256 _bet, address _participant) external returns (bool);
    function recordTransfer(uint256 _bet, uint256 _amount) external returns (bool);
}