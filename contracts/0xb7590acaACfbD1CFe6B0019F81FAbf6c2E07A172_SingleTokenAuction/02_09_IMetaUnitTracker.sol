// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaUnitTracker {
    struct Transaction { address owner_of; uint256 value; uint256 timestamp; }

    function track(address eth_address_, uint256 value_) external;
    function getUserResalesSum(address eth_address_) external view returns(uint256);
    function getUserTransactionQuantity(address eth_address_) external view returns(uint256);
    function getTransactions() external view returns (Transaction[] memory);
    function getTransactionsForPeriod(uint256 from_, uint256 to_) external view returns (address[] memory, uint256[] memory);
}