//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@fractal-framework/core-contracts/contracts/interfaces/IDAOFactory.sol";

interface IMetaFactory {
    event DAOAndModulesCreated(
        address dao,
        address accessControl,
        address[] modules
    );

    error UnequalArrayLengths();
    error InvalidModuleAddressToPass();
    error FactoryCallFailed();

    struct ModuleFactoryCallData {
        address factory;
        bytes[] data;
        uint256 value;
        uint256[] newContractAddressesToPass;
        uint256 addressesReturned;
    }

    struct ModuleActionData {
        uint256[] contractIndexes;
        string[] functionDescs;
        string[][] roles;
    }

    /// @notice A factory contract for deploying DAOs along with any desired modules within one transaction
    /// @param daoFactory The address of the DAO factory
    /// @param metaFactoryTempRoleIndex The index of which role specified in createDAOParams should be temporarily given to the MetaFactory
    /// @param createDAOParams The struct of parameters used for creating the DAO and Access Control contracts
    /// @param moduleFactoriesCallData The calldata required for each module factory call
    /// @param moduleActionData Struct of functionDescs and roles to setup for each newly created module
    /// @param roleModuleMembers Array of which newly created modules should be given each role
    /// @return Array of addresses of the newly created modules
    function createDAOAndModules(
        address daoFactory,
        uint256 metaFactoryTempRoleIndex,
        IDAOFactory.CreateDAOParams memory createDAOParams,
        ModuleFactoryCallData[] memory moduleFactoriesCallData,
        ModuleActionData memory moduleActionData,
        uint256[][] memory roleModuleMembers
    ) external returns (address[] memory);
}