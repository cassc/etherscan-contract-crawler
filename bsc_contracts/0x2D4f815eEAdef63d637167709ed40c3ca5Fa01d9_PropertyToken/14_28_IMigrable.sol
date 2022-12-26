pragma solidity ^0.8.0;

interface IMigrable {
    function createMigrableSnapshot() external;

    function lastMigrableSnapshot() external view returns (uint256);
}