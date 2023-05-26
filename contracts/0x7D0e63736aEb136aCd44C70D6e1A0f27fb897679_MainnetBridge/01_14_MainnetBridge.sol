pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Bridge.sol";

contract MainnetBridge is Bridge {
 
  // The mainnet bridge isn't altered at all.
  // However we need to call the _deposit and _executeProposal functions
  // that have been made internal.

  constructor (uint8 chainID, address[] memory initialRelayers, uint initialRelayerThreshold, uint256 fee, uint256 expiry, address forwarder) Bridge(chainID, initialRelayers, initialRelayerThreshold, fee, expiry, forwarder) public {}

  function deposit(uint8 destinationChainID, bytes32 resourceID, bytes calldata data) external whenNotPaused {
    _deposit(destinationChainID, resourceID, data);
  }

  function executeProposal(uint8 chainID, uint64 depositNonce, bytes calldata data, bytes32 resourceID) external onlyRelayers whenNotPaused {
    _executeProposal(chainID, depositNonce, data, resourceID);
  }
}