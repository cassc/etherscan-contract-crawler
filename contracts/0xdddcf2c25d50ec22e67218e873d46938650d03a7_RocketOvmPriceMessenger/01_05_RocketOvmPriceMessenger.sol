// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@rocketpool/interface/RocketStorageInterface.sol";
import "@rocketpool/interface/network/RocketNetworkBalancesInterface.sol";
import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import "./RocketOvmPriceOracle.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Retrieves the rETH exchange rate from Rocket Pool and submits it to the oracle contract on OVM
contract RocketOvmPriceMessenger {
    // Immutables
    ICrossDomainMessenger immutable ovmL1CrossDomainMessenger;
    RocketStorageInterface immutable rocketStorage;
    RocketOvmPriceOracle immutable rocketL2OvmPriceOracle;
    bytes32 immutable rocketNetworkBalancesKey;

    /// @notice The most recently submitted rate
    uint256 lastRate;

    constructor(RocketStorageInterface _rocketStorage, RocketOvmPriceOracle _rocketL2OvmPriceOracle, ICrossDomainMessenger _ovmL1CrossDomainMessenger) {
        rocketStorage = _rocketStorage;
        rocketL2OvmPriceOracle = _rocketL2OvmPriceOracle;
        ovmL1CrossDomainMessenger = _ovmL1CrossDomainMessenger;
        // Precompute storage key for RocketNetworkBalances address
        rocketNetworkBalancesKey = keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances"));
    }

    /// @notice Returns whether the rate has changed since it was last submitted
    function rateStale() external view returns (bool) {
        return rate() != lastRate;
    }

    /// @notice Returns the calculated rETH exchange rate
    function rate() public view returns (uint256) {
        // Retrieve the inputs from RocketNetworkBalances and calculate the rate
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(rocketStorage.getAddress(rocketNetworkBalancesKey));
        uint256 supply = rocketNetworkBalances.getTotalRETHSupply();
        if (supply == 0) {
            return 0;
        }
        return 1 ether * rocketNetworkBalances.getTotalETHBalance() / supply;
    }

    /// @notice Submits the current rETH exchange rate to the OVM cross domain messenger contract
    function submitRate() external {
        lastRate = rate();
        // Send the cross chain message
        ovmL1CrossDomainMessenger.sendMessage(
            address(rocketL2OvmPriceOracle),
            abi.encodeWithSelector(
                rocketL2OvmPriceOracle.updateRate.selector,
                lastRate
            ),
            500000
        );
    }
}