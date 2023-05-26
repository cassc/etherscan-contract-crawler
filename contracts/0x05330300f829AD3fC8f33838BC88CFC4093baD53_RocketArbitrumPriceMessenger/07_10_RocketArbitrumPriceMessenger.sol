// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";

import "rocketpool/contracts/interface/network/RocketNetworkBalancesInterface.sol";
import "rocketpool/contracts/interface/RocketStorageInterface.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Retrieves the rETH exchange rate from Rocket Pool and submits it to the oracle contract on Polygon
contract RocketArbitrumPriceMessenger {
    // Immutables
    RocketStorageInterface immutable rocketStorage;
    bytes32 immutable rocketNetworkBalancesKey;
    IInbox immutable public inbox;

    /// @notice The most recently submitted rate
    uint256 lastRate;

    /// @notice Target address of the oracle contract on L2
    address public l2Target;

    constructor(RocketStorageInterface _rocketStorage, address _inbox) {
        rocketStorage = _rocketStorage;
        inbox = IInbox(_inbox);
        // Precompute storage key for RocketNetworkBalances address
        rocketNetworkBalancesKey = keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances"));
    }

    /// @notice Sets the L2 oracle contract address
    function updateL2Target(address _l2Target) public {
        require(l2Target == address(0));
        l2Target = _l2Target;
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

    /// @notice Submits the current rETH exchange rate to the Arbitrum cross domain messenger contract
    /// @param _maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
    /// @param _gasLimit Max gas deducted from user's L2 balance to cover L2 execution
    /// @param _gasPriceBid price bid for L2 execution
    function submitRate(uint256 _maxSubmissionCost, uint256 _gasLimit, uint256 _gasPriceBid) external payable {
        lastRate = rate();
        // Send the cross chain message
        bytes memory data = abi.encodeWithSignature('updateRate(uint256)', lastRate);
        inbox.createRetryableTicket{value: msg.value}(
            l2Target,           // Target address
            0,                  // Call value
            _maxSubmissionCost, // Max submission cost
            msg.sender,         // Fee refund address on L2
            msg.sender,         // Value refund on L2
            _gasLimit,          // Max gas
            _gasPriceBid,       // Gas price bid
            data
        );
    }
}