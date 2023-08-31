pragma solidity 0.8.18;

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}