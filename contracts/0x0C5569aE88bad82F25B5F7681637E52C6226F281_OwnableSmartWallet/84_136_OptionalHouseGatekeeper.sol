pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { IGateKeeper } from "../interfaces/IGateKeeper.sol";
import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";

/// @title Liquid Staking Derivative Network Gatekeeper that only lets knots from within the network join the network house
contract OptionalHouseGatekeeper is IGateKeeper {

    /// @notice Address of the core registry for the associated liquid staking network
    ILiquidStakingManager public liquidStakingManager;

    constructor(address _manager) {
        liquidStakingManager = ILiquidStakingManager(_manager);
    }

    /// @notice Method called by the house before admitting a new KNOT member and giving house sETH
    function isMemberPermitted(bytes calldata _blsPublicKeyOfKnot) external override view returns (bool) {
        return liquidStakingManager.isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot) && !liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot);
    }
}