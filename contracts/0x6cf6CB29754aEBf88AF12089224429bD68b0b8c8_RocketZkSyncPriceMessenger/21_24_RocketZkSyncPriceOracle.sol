// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @author Kane Wallmann (Rocket Pool)
/// @notice Receives updates from L1 on the canonical rETH exchange rate
contract RocketZkSyncPriceOracle {
    // Events
    event RateUpdated(uint256 rate);

    /// @notice The rETH exchange rate in the form of how much ETH 1 rETH is worth
    uint256 public rate;

    /// @notice The timestamp of the block in which the rate was last updated
    uint256 public lastUpdated;

    /// @notice Should be set to the address of the messenger on L1
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = _newOwner;
    }

    /// @notice Called by the messenger contract on L1 to update the exchange rate
    function updateRate(uint256 _newRate) external {
        // Only allow calls from self
        require(msg.sender == owner, "Not owner");
        // Update state
        rate = _newRate;
        lastUpdated = block.timestamp;
        // Emit event
        emit RateUpdated(_newRate);
    }
}