pragma solidity ^0.8.17;

import "./Context.sol";

/**
 * Equivalent to owner, but only for managing rewards
 */
 // SPDX-License-Identifier: MIT
contract RewardsMonitoring is Context {

    address private _monitor;
    uint256 private _lockTime;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _monitor = _msgSender();
    }

    function monitor() public view returns (address) {
        return _monitor;
    }

    modifier onlyRewardsMonitor() {
        require(isMonitor(), "Monitor: caller is not the rewards monitor");
        _;
    }

    function isMonitor() public view returns(bool) {
        return _monitor == _msgSender();
    }
    
    function renounceMonitor() public virtual onlyRewardsMonitor {
        _monitor = address(0);
    }
    
}