pragma solidity ^0.8.0;

interface ILottery {
    function getBalance(address staker) external view returns (uint256 balance);
}