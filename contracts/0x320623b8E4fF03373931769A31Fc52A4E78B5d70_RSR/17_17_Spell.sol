// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.4;

/**
 * @title Spell
 * @dev A one-time-use atomic sequence of actions, hasBeenCast by RSR for contract changes.
 */
abstract contract Spell {
    address public immutable rsrAddr;

    bool public hasBeenCast;

    constructor(address rsr_) {
        rsrAddr = rsr_;
    }

    function cast() external {
        require(msg.sender == rsrAddr, "rsr only");
        require(!hasBeenCast, "spell already cast");
        hasBeenCast = true;
        spell();
    }

    /// A derived Spell overrides spell() to enact its intended effects.
    function spell() internal virtual;
}