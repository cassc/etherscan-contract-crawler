pragma solidity ^0.8.17;

// SPDX-License-Identifier: Apache-2.0

import "./ERC20.sol";
import "./Ownable.sol";

abstract contract Token is ERC20, Ownable {

    address[] private excludedFrom;
    mapping(address => bool) private isAddressExcluded;
    
    event ExcludeFrom(address wallet);
    event IncludeIn(address wallet);
    
    function deleteExcluded(uint index) internal {
        require(index < excludedFrom.length, "Index is greater than array length");
        excludedFrom[index] = excludedFrom[excludedFrom.length - 1];
        excludedFrom.pop();
    }
    
    function getExcludedBalances() internal view returns (uint256) {
        uint256 totalExcludedHoldings = 0;
        for (uint i = 0; i < excludedFrom.length; i++) {
            totalExcludedHoldings += balanceOf(excludedFrom[i]);
        }
        return totalExcludedHoldings;
    }
    
    function excludeFrom(address wallet) public onlyOwner {
        require(!isAddressExcluded[wallet], "Address is already excluded from ");
        excludedFrom.push(wallet);
        isAddressExcluded[wallet] = true;
        emit ExcludeFrom(wallet);
    }
    
    function includeIn(address wallet) external onlyOwner {
        require(isAddressExcluded[wallet], "Address is not excluded from ");
        for (uint i = 0; i < excludedFrom.length; i++) {
            if (excludedFrom[i] == wallet) {
                isAddressExcluded[wallet] = false;
                deleteExcluded(i);
                break;
            }
        }
        emit IncludeIn(wallet);
    }
    
    function isExcludedFrom(address wallet) external view returns (bool) {
        return isAddressExcluded[wallet];
    }
    
    function getAllExcludedFrom() external view returns (address[] memory) {
        return excludedFrom;
    }
    
    function getSupply() public view returns (uint256) {
        return _totalSupply - getExcludedBalances();
    }
}