// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@fx-portal/tunnel/FxBaseRootTunnel.sol";

import "rocketpool/contracts/interface/network/RocketNetworkBalancesInterface.sol";
import "rocketpool/contracts/interface/RocketStorageInterface.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Retrieves the rETH exchange rate from Rocket Pool and submits it to the oracle contract on Polygon
contract RocketPolygonPriceMessenger is FxBaseRootTunnel {
    // Immutables
    RocketStorageInterface immutable rocketStorage;
    bytes32 immutable rocketNetworkBalancesKey;

    /// @notice The most recently submitted rate
    uint256 lastRate;

    constructor(RocketStorageInterface _rocketStorage, address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rocketStorage = _rocketStorage;
        // Precompute storage key for RocketNetworkBalances address
        rocketNetworkBalancesKey = keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances"));
    }

    /// @notice Not used
    function _processMessageFromChild(bytes memory data) internal override {
        revert();
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

    /// @notice Submits the current rETH exchange rate to the L2 contract
    function submitRate() external {
        lastRate = rate();
        // Send the cross chain message
        bytes memory data = abi.encodeWithSignature('updateRate(uint256)', lastRate);
        _sendMessageToChild(data);
    }
}