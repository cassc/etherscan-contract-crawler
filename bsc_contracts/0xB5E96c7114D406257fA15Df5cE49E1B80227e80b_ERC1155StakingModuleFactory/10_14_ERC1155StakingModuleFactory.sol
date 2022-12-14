/*
ERC721StakingModuleFactory

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

import "./interfaces/IModuleFactory.sol";
import "./ERC1155StakingModule.sol";

/**
 * @title ERC721 staking module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC721StakingModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC1155StakingModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(bytes calldata data)
        external
        override
        returns (address)
    {
        // validate
        require(data.length == 32, "Invalid calldata");

        // parse staking token
        address token;
        assembly {
            token := calldataload(68)
        }

        // create module
        ERC1155StakingModule module =
            new ERC1155StakingModule(token, address(this));
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}