// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@fx-portal/tunnel/FxBaseChildTunnel.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Receives updates from L1 on the canonical rETH exchange rate
contract RocketPolygonPriceOracle is FxBaseChildTunnel {
    // Events
    event RateUpdated(uint256 rate);

    /// @notice The rETH exchange rate in the form of how much ETH 1 rETH is worth
    uint256 public rate;

    /// @notice The timestamp of the block in which the rate was last updated
    uint256 public lastUpdated;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {
    }

    /// @notice Processes an incoming message from L1
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // Execute the transaction on self
        (bool success, ) = address(this).call(data);
        require(success, "Failed to execute transaction on child");
    }

    /// @notice Called by the messenger contract on L1 to update the exchange rate
    function updateRate(uint256 _newRate) external {
        // Only allow calls from self
        require(msg.sender == address(this));
        // Update state
        rate = _newRate;
        lastUpdated = block.timestamp;
        // Emit event
        emit RateUpdated(_newRate);
    }
}