// commit 05f8641fe3078eefe6ddc9ac42345c5e969107f1
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseACL.sol";
import "EnumerableSet.sol";

abstract contract FarmingBaseACL is BaseACL {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    //roles => pool id whitelist
    EnumerableSet.UintSet farmPoolIdWhitelist;
    EnumerableSet.AddressSet farmPoolAddressWhitelist;

    //events
    event AddPoolAddressWhitelist(address indexed _poolAddress, address indexed user);
    event RemovePoolAddressWhitelist(address indexed _poolAddress, address indexed user);
    event AddPoolIdWhitelist(uint256 indexed _poolId, address indexed user);
    event RemovePoolIdWhitelist(uint256 indexed _poolId, address indexed user);

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    function addPoolIds(uint256[] calldata _poolIds) external onlyOwner {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            if (farmPoolIdWhitelist.add(_poolIds[i])) {
                emit AddPoolIdWhitelist(_poolIds[i], msg.sender);
            }
        }
    }

    function removePoolIds(uint256[] calldata _poolIds) external onlyOwner {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            if (farmPoolIdWhitelist.remove(_poolIds[i])) {
                emit RemovePoolIdWhitelist(_poolIds[i], msg.sender);
            }
        }
    }

    function addPoolAddresses(address[] calldata _poolAddresses) external onlyOwner {
        for (uint256 i = 0; i < _poolAddresses.length; i++) {
            if (farmPoolAddressWhitelist.add(_poolAddresses[i])) {
                emit AddPoolAddressWhitelist(_poolAddresses[i], msg.sender);
            }
        }
    }

    function removePoolAddresses(address[] calldata _poolAddresses) external onlyOwner {
        for (uint256 i = 0; i < _poolAddresses.length; i++) {
            if (farmPoolAddressWhitelist.remove(_poolAddresses[i])) {
                emit RemovePoolAddressWhitelist(_poolAddresses[i], msg.sender);
            }
        }
    }

    function getPoolIdWhiteList() external view returns (uint256[] memory) {
        return farmPoolIdWhitelist.values();
    }

    function getPoolAddressWhiteList() external view returns (address[] memory) {
        return farmPoolAddressWhitelist.values();
    }

    function _checkAllowPoolId(uint256 _poolId) internal view {
        require(farmPoolIdWhitelist.contains(_poolId), "pool id not allowed");
    }

    function _checkAllowPoolAddress(address _poolAddress) internal view {
        require(farmPoolAddressWhitelist.contains(_poolAddress), "pool address not allowed");
    }
}