pragma solidity ^0.8.0;

interface IMonthlyLottery {
    function addParticipant(address _participant) external returns (bool);
}