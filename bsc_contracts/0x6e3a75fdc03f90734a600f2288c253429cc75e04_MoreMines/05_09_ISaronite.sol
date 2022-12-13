// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ISaronite {
    function storeSaroniteDouble(address account1, address account2) external;
    function storeSaronite(address account) external;
    function addSaronitePerDay(address, uint256) external;
    function removeSaronitePerDay(address, uint256) external;
    function useSaronite(address, uint256) external;
}