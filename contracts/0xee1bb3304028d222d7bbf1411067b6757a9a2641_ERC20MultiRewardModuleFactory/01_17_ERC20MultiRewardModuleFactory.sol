/*
ERC20MultiRewardModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20MultiRewardModule.sol";

/**
 * @title ERC20 multi reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20MultiRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20MultiRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 64, "mrmf1");

        // parse constructor arguments
        uint256 vestingStart;
        uint256 vestingPeriod;
        assembly {
            vestingStart := calldataload(100)
            vestingPeriod := calldataload(132)
        }

        // create module
        ERC20MultiRewardModule module = new ERC20MultiRewardModule(
            vestingStart,
            vestingPeriod,
            config,
            address(this)
        );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}