pragma solidity =0.6.6;

interface ILottery {
    function enter(uint256 ticketCount, address account) external;
}