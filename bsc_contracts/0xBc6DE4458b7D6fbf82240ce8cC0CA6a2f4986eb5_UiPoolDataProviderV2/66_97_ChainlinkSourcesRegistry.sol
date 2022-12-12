// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

contract ChainlinkSourcesRegistry is Ownable {
  /// @dev Mapping of current stored asset => underlying Chainlink aggregator
  mapping (address => address) public aggregatorsOfAssets;
  
  event AggregatorUpdated(address token, address aggregator);

    
  function updateAggregators(address[] memory assets, address[] memory aggregators) external onlyOwner {    
    for(uint256 i = 0; i < assets.length; i++) {
      aggregatorsOfAssets[assets[i]] = aggregators[i];
      emit AggregatorUpdated(assets[i], aggregators[i]);
    }
  }
}