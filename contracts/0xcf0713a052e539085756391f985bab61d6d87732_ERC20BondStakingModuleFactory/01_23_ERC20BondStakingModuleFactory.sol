/*
ERC20BondStakingModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20BondStakingModule.sol";

/**
 * @title ERC20 bond staking module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20BondStakingModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20BondStakingModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 64, "bsmf1");

        // parse staking token
        uint256 period;
        bool burndown;
        assembly {
            period := calldataload(100)
            burndown := calldataload(132)
        }

        // create module
        ERC20BondStakingModule module = new ERC20BondStakingModule(
            period,
            burndown,
            config,
            address(this)
        );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}