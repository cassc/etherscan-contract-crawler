/*
ERC20FriendlyRewardModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20FriendlyRewardModule.sol";

/**
 * @title ERC20 friendly reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20FriendlyRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20FriendlyRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 96, "frmf1");

        // parse constructor arguments
        address token;
        uint256 penaltyStart;
        uint256 penaltyPeriod;
        assembly {
            token := calldataload(100)
            penaltyStart := calldataload(132)
            penaltyPeriod := calldataload(164)
        }

        // create module
        ERC20FriendlyRewardModule module = new ERC20FriendlyRewardModule(
            token,
            penaltyStart,
            penaltyPeriod,
            config,
            address(this)
        );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}