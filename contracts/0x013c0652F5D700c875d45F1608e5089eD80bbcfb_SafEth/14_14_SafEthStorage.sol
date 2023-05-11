// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IDerivative.sol";

/**
 @notice - Storage abstraction for SafEth contract
 @dev - Upgradeability Rules:
        DO NOT change existing variable names or types
        DO NOT change order of variables
        DO NOT remove any variables
        ONLY add new variables at the end
        Constant values CAN be modified on upgrade
*/
contract SafEthStorage {
    struct Derivatives {
        IDerivative derivative;
        uint256 weight;
        bool enabled;
    }

    bool public pauseStaking; // true if staking is paused
    bool public pauseUnstaking; // true if unstaking is pause
    uint256 public derivativeCount; // amount of derivatives added to contract
    uint256 public totalWeight; // total weight of all derivatives (used to calculate percentage of derivative)
    uint256 public minAmount; // minimum amount to stake
    uint256 public maxAmount; // maximum amount to stake
    mapping(uint256 => Derivatives) public derivatives; // derivatives in the system
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}