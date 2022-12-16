// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRewards {

    /**
     * Events
     */

    event PoolInited(address token, uint256 rate);

    event HelioTokenChanged(address newToken);

    event HelioOracleChanged(address newOracle);

    event RateChanged(address token, uint256 newRate);

    event RewardsLimitChanged(uint256 newLimit);

    event Cage(address user);

    event Uncage(address user);

    event Claimed(address indexed user, uint256 amount);

    /**
     * Methods
     */

    function drop(address token, address usr) external;
}