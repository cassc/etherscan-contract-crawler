// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PoolFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private pools;
    EnumerableSet.AddressSet private poolGenerators;
    
    mapping(address => EnumerableSet.AddressSet) private userPools;
    
    function adminAllowPoolGenerator (address _address, bool _allow) public onlyOwner {
        if (_allow) {
            poolGenerators.add(_address);
        } else {
            poolGenerators.remove(_address);
        }
    }
    
    /**
     * @notice called by a registered PoolGenerator upon Pool creation
     */
    function registerPool (address _poolAddress) public {
        require(poolGenerators.contains(msg.sender), 'FORBIDDEN');
        pools.add(_poolAddress);
    }
    
    /**
     * @notice Number of allowed PoolGenerators
     */
    function poolGeneratorsLength() external view returns (uint256) {
        return poolGenerators.length();
    }
    
    /**
     * @notice Gets the address of a registered PoolGenerator at specifiex index
     */
    function poolGeneratorAtIndex(uint256 _index) external view returns (address) {
        return poolGenerators.at(_index);
    }
    
    /**
     * @notice The length of all pools on the platform
     */
    function poolsLength() external view returns (uint256) {
        return pools.length();
    }
    
    /**
     * @notice gets a pool at a specific index. Although using Enumerable Set, since pools are only added and not removed this will never change
     * @return the address of the Pool contract at index
     */
    function poolAtIndex(uint256 _index) external view returns (address) {
        return pools.at(_index);
    }
    
    /**
     * @notice called by a Pool contract when lp token balance changes from 0 to > 0 to allow tracking all pools a user is active in
     */
    function userEnteredPool(address _user) public {
        // msg.sender = pool contract
        require(pools.contains(msg.sender), 'FORBIDDEN');
        EnumerableSet.AddressSet storage set = userPools[_user];
        set.add(msg.sender);
    }
    
    /**
     * @notice called by a Pool contract when all LP tokens have been withdrawn, removing the pool from the users active pool list
     */
    function userLeftPool(address _user) public {
        // msg.sender = pool contract
        require(pools.contains(msg.sender), 'FORBIDDEN');
        EnumerableSet.AddressSet storage set = userPools[_user];
        set.remove(msg.sender);
    }
    
    /**
     * @notice returns the number of pools the user is active in
     */
    function userPoolsLength(address _user) external view returns (uint256) {
        EnumerableSet.AddressSet storage set = userPools[_user];
        return set.length();
    }
    
    /**
     * @notice called by a Pool contract when all LP tokens have been withdrawn, removing the pool from the users active pool list
     * @return the address of the Pool contract the user is pooling
     */
    function userPoolAtIndex(address _user, uint256 _index) external view returns (address) {
        EnumerableSet.AddressSet storage set = userPools[_user];
        return set.at(_index);
    }
    
}