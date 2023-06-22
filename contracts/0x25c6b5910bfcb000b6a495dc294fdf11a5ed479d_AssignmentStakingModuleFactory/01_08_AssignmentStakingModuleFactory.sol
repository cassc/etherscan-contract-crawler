/*
AssignmentStakingModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./AssignmentStakingModule.sol";

/**
 * @title Assignment staking module factory
 *
 * @notice this factory contract handles deployment for the
 * AssignmentStakingModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract AssignmentStakingModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(address, bytes calldata)
        external
        override
        returns (address)
    {
        // create module
        AssignmentStakingModule module =
            new AssignmentStakingModule(address(this));
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}