pragma solidity ^0.8.4;

// SPDX-License-Identifier: Apache-2.0

import "./ERC20.sol";
import "./Ownable.sol";

abstract contract RewardsToken is ERC20, Ownable {

    address[] private excludedFromRewards;
    mapping(address => bool) private isAddressExcluded;
    
    event ExcludeFromRewards(address wallet);
    event IncludeInRewards(address wallet);
    
    function deleteExcluded(uint index) internal {
        require(index < excludedFromRewards.length, "Index is greater than array length");
        excludedFromRewards[index] = excludedFromRewards[excludedFromRewards.length - 1];
        excludedFromRewards.pop();
    }
    
    function getExcludedBalances() internal view returns (uint256) {
        uint256 totalExcludedHoldings = 0;
        for (uint i = 0; i < excludedFromRewards.length; i++) {
            totalExcludedHoldings += balanceOf(excludedFromRewards[i]);
        }
        return totalExcludedHoldings;
    }
    
    function excludeFromRewards(address wallet) public onlyOwner {
        require(!isAddressExcluded[wallet], "Address is already excluded from rewards");
        excludedFromRewards.push(wallet);
        isAddressExcluded[wallet] = true;
        emit ExcludeFromRewards(wallet);
    }
    
    function includeInRewards(address wallet) external onlyOwner {
        require(isAddressExcluded[wallet], "Address is not excluded from rewards");
        for (uint i = 0; i < excludedFromRewards.length; i++) {
            if (excludedFromRewards[i] == wallet) {
                isAddressExcluded[wallet] = false;
                deleteExcluded(i);
                break;
            }
        }
        emit IncludeInRewards(wallet);
    }
    
    function isExcludedFromRewards(address wallet) external view returns (bool) {
        return isAddressExcluded[wallet];
    }
    
    function getAllExcludedFromRewards() external view returns (address[] memory) {
        return excludedFromRewards;
    }
    
    function getRewardsSupply() public view returns (uint256) {
        return _totalSupply - getExcludedBalances();
    }
}