/*
ERC20CompetitiveRewardModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20CompetitiveRewardModule.sol";

/**
 * @title ERC20 competitive reward module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20CompetitiveRewardModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20CompetitiveRewardModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 128, "crmf1");

        // parse constructor arguments
        address token;
        uint256 bonusMin;
        uint256 bonusMax;
        uint256 bonusPeriod;
        assembly {
            token := calldataload(100)
            bonusMin := calldataload(132)
            bonusMax := calldataload(164)
            bonusPeriod := calldataload(196)
        }

        // create module
        ERC20CompetitiveRewardModule module = new ERC20CompetitiveRewardModule(
            token,
            bonusMin,
            bonusMax,
            bonusPeriod,
            config,
            address(this)
        );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}