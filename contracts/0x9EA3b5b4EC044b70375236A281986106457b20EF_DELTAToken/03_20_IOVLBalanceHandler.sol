pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

interface IOVLBalanceHandler {
    function handleBalanceCalculations(address, address) external view returns (uint256);
}