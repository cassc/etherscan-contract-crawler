// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICostManagerFactoryHelper.sol";

// used for factory
abstract contract CostManagerFactoryHelper is ICostManagerFactoryHelper, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public costManager;

    EnumerableSet.AddressSet private _renouncedOverrideCostManager;

    event RenouncedOverrideCostManagerForInstance(address instance);
    
    constructor(address costManager_) {
        _setCostManager(costManager_);
    }

    /**
    * @dev set the costManager for all future calls to produce()
    */
    function setCostManager(address costManager_) public onlyOwner {
        _setCostManager(costManager_);
    }
    
    /**
    * @dev renounces ability to override cost manager on instances
    */
    function renounceOverrideCostManager(address instance) public onlyOwner {
        _renouncedOverrideCostManager.add(instance);
        emit RenouncedOverrideCostManagerForInstance(instance);
    }
    
    /** 
    * @dev instance can call this to find out whether a given address can set the cost manager contract
    * @param account the address to test
    * @param instance the instance to test
    */
    function canOverrideCostManager(
        address account, 
        address instance
    ) 
        external 
        virtual 
        override
        view
        returns (bool) 
    {
        return (account == owner() && !_renouncedOverrideCostManager.contains(instance));
    }

    function _setCostManager(address costManager_) internal {
        costManager = costManager_;
    }
}