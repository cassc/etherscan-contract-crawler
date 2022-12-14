/*
ERC20CompetitiveRewardModuleFactory

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

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
    function createModule(bytes calldata data)
        external
        override
        returns (address)
    {
        // validate
        require(data.length == 128, "crmf1");

        // parse constructor arguments
        address token;
        uint256 bonusMin;
        uint256 bonusMax;
        uint256 bonusPeriod;
        assembly {
            token := calldataload(68)
            bonusMin := calldataload(100)
            bonusMax := calldataload(132)
            bonusPeriod := calldataload(164)
        }

        // create module
        ERC20CompetitiveRewardModule module =
            new ERC20CompetitiveRewardModule(
                token,
                bonusMin,
                bonusMax,
                bonusPeriod,
                address(this)
            );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}