// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract D3PoolQuota is Ownable {
    // token => bool
    mapping(address => bool) public isUsingQuota;
    // token => bool
    mapping(address => bool) public hasDefaultQuota;
    // token => quota
    mapping(address => uint256) public defaultQuota;
    // token => (pool => quota)
    mapping(address => mapping(address => uint256)) public poolQuota;

    /// @notice Set pool quota
    /// @param token The token address
    /// @param pools The list of pool addresses
    /// @param quotas The list of quota corresponding to the pool list
    function setPoolQuota(address token, address[] calldata pools, uint256[] calldata quotas) external onlyOwner {
        require(pools.length == quotas.length, "PARAMS_LENGTH_NOT_MATCH");
        for (uint256 i = 0; i < pools.length; i++) {
            poolQuota[token][pools[i]] = quotas[i];
        }
    }

    /// @notice Enable quota for a token
    function enableQuota(address token, bool status) external onlyOwner {
        isUsingQuota[token] = status;
    }

    /// @notice Enable default quota for a token
    function enableDefaultQuota(address token, bool status) external onlyOwner {
        hasDefaultQuota[token] = status;
    }

    /// @notice Set default quota for a token
    /// @notice Default quota means every pool has the same quota
    function setDefaultQuota(address token, uint256 amount) external onlyOwner {
        defaultQuota[token] = amount;
    }

    /// @notice Get the pool quota for a token
    function getPoolQuota(address pool, address token) external view returns (uint256) {
        if (isUsingQuota[token]) {
            if (hasDefaultQuota[token]) {
                return defaultQuota[token];
            } else {
                return poolQuota[token][pool];
            }
        } else {
            return type(uint256).max;
        }
    }
}