// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IGovernor.sol";
import "contracts/libraries/errors/GovernanceErrors.sol";

/// @custom:salt Governance
/// @custom:deploy-type deployUpgradeable
contract Governance is IGovernor {
    // dummy contract
    address internal immutable _factory;

    constructor() {
        _factory = msg.sender;
    }

    function updateValue(uint256 epoch, uint256 key, bytes32 value) external {
        if (msg.sender != _factory) {
            revert GovernanceErrors.OnlyFactoryAllowed(msg.sender);
        }
        emit ValueUpdated(epoch, key, value, msg.sender);
    }
}