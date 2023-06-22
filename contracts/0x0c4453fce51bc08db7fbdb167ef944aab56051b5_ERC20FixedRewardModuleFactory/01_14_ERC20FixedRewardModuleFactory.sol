/*
ERC20FixedRewardModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20FixedRewardModule.sol";

/**
 * @title ERC20 fixed reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20FixedRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20FixedRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 96, "xrmf1");

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
        ERC20FixedRewardModule module = new ERC20FixedRewardModule(
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