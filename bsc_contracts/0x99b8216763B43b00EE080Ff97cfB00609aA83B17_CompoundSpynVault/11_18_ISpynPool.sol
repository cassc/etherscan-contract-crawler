pragma solidity ^0.8.0;

interface ISpynPool {
    function safeTransfer(address _to, uint256 _amount) external returns (bool);
}