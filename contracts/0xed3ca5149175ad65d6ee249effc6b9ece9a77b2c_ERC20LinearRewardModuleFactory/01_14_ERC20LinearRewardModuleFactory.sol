/*
ERC20LinearRewardModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20LinearRewardModule.sol";

/**
 * @title ERC20 linear reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20LinearRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20LinearRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 96, "lrmf1");

        // parse constructor arguments
        address token;
        uint256 period;
        uint256 rate;
        assembly {
            token := calldataload(100)
            period := calldataload(132)
            rate := calldataload(164)
        }

        // create module
        ERC20LinearRewardModule module = new ERC20LinearRewardModule(
            token,
            period,
            rate,
            config,
            address(this)
        );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}