// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract TaxCollector {
    event TaxReceived(uint256 amount, address add, uint256 timestamp);

    function onTaxReceived(
        uint256 amount,
        address add,
        uint256 timestamp
    ) external {
        emit TaxReceived(amount, add, timestamp);
    }
}