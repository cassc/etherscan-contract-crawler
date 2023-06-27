// SPDX-License-Identifier: GPL-3.0


import "./AccessControlledOffchainAggregator.sol";

pragma solidity <0.9.0;

contract ChainlinkMigrator {
    
    function transferPayeeshipTo(address[] calldata aggregatorAddresses, address ocrNodeAddress, address payeeAddress) external {
        uint aggregatorsCount = aggregatorAddresses.length;
        for(uint i = 0; i < aggregatorsCount; i++) {
            AccessControlledOffchainAggregator aggregator = AccessControlledOffchainAggregator(aggregatorAddresses[i]);
            aggregator.transferPayeeship(ocrNodeAddress, payeeAddress);
        }
    }

    function acceptPayeeship(address[] calldata aggregatorAddresses, address ocrNodeAddress) external {
        uint aggregatorsCount = aggregatorAddresses.length;
        for(uint i = 0; i < aggregatorsCount; i++) {
            AccessControlledOffchainAggregator aggregator = AccessControlledOffchainAggregator(aggregatorAddresses[i]);
            aggregator.acceptPayeeship(ocrNodeAddress);
        }
    }
}