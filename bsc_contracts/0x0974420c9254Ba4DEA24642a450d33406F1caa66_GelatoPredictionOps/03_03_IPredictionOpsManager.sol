pragma solidity ^0.8.13;

interface IPredictionOpsManager {
    function execute() external;

    function canPerformTask(uint256 _delay) external view returns (bool);
}