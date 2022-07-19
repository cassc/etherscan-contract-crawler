pragma solidity ^0.8.0;

interface IxTokenManager {
    function isManager(address manager, address fund) external view returns (bool);
}