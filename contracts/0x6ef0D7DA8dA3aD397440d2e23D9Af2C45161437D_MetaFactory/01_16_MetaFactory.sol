//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IMetaFactory.sol";
import "@fractal-framework/core-contracts/contracts/interfaces/IDAO.sol";
import "@fractal-framework/core-contracts/contracts/interfaces/IAccessControlDAO.sol";

/// @notice A factory contract for deploying DAOs along with any desired modules within one transaction
contract MetaFactory is IMetaFactory, ERC165 {
    /// @notice Creates a DAO, Access Control, and any modules specified
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
    ) external returns (address[] memory) {
        if (
            moduleActionData.contractIndexes.length !=
            moduleActionData.functionDescs.length ||
            moduleActionData.contractIndexes.length !=
            moduleActionData.roles.length ||
            createDAOParams.roles.length != roleModuleMembers.length
        ) {
            revert UnequalArrayLengths();
        }

        uint256 modulesLength = moduleFactoriesCallData.length;

        // Get the number of new module addresses to be created
        uint256 newContractAddressesLength = 2;
        for (uint256 i; i < modulesLength; ) {
            newContractAddressesLength += moduleFactoriesCallData[i]
                .addressesReturned;

            unchecked {
                i++;
            }
        }

        address[] memory newContractAddresses = new address[](
            newContractAddressesLength
        );

        // Give this contract a temporary role so it can execute through the DAO
        uint256 tempRoleMembersLength = createDAOParams
            .members[metaFactoryTempRoleIndex]
            .length;
        address[] memory tempRoleNewMembers = new address[](
            tempRoleMembersLength + 1
        );

        for (uint256 i; i < tempRoleMembersLength; ) {
            tempRoleNewMembers[i] = createDAOParams.members[
                metaFactoryTempRoleIndex
            ][i];
            unchecked {
                i++;
            }
        }

        tempRoleNewMembers[tempRoleMembersLength] = address(this);

        createDAOParams.members[metaFactoryTempRoleIndex] = tempRoleNewMembers;


        // Create the DAO and Access Control contracts
        (address dao, address accessControl) = IDAOFactory(daoFactory)
            .createDAO(msg.sender, createDAOParams);

        newContractAddresses[0] = dao;
        newContractAddresses[1] = accessControl;

        // Create the DAO modules
        newContractAddresses = createModules(newContractAddresses, moduleFactoriesCallData);

        addActionsRoles(moduleActionData, newContractAddresses);

        addModuleRoles(
            createDAOParams.roles,
            roleModuleMembers,
            newContractAddresses
        );

        // Renounce the MetaFactory temporary role
        IAccessControlDAO(newContractAddresses[1]).renounceRole(
            createDAOParams.roles[metaFactoryTempRoleIndex],
            address(this)
        );

        // Create array of created module addresses to emit in event
        address[] memory moduleAddresses = new address[](
            newContractAddresses.length - 2
        );
        for (uint256 i; i < moduleAddresses.length; ) {
            moduleAddresses[i] = newContractAddresses[i + 2];

            unchecked {
                i++;
            }
        }

        emit DAOAndModulesCreated(
            newContractAddresses[0],
            newContractAddresses[1],
            moduleAddresses
        );

        return newContractAddresses;
    }

    /// @notice Creates each new module contract
    /// @param newContractAddresses The incomplete array of new contract addresses
    /// @param moduleFactoriesCallData The calldata required for each module factory call
    /// @return The newContractAddresses array updated with new addresses from modules creation
    function createModules(
        address[] memory newContractAddresses,
        ModuleFactoryCallData[] memory moduleFactoriesCallData
    ) private returns (address[] memory) {
        uint256 newContractAddressIndex = 2;

        // Loop through each module to be created
        for (uint256 i; i < moduleFactoriesCallData.length;) {
            uint256 newContractAddressesToPassLength = moduleFactoriesCallData[
                i
            ].newContractAddressesToPass.length;

            bytes[] memory newData = new bytes[](
                moduleFactoriesCallData[i].data.length +
                    newContractAddressesToPassLength
            );

            // Add new contract addresses to module calldata
            for (uint256 j; j < newContractAddressesToPassLength;) {
                if (
                    moduleFactoriesCallData[i].newContractAddressesToPass[j] >=
                    i + 2
                ) {
                    revert InvalidModuleAddressToPass();
                }

                // Encode the new contract address into bytes
                newData[j] = abi.encode(
                    newContractAddresses[
                        moduleFactoriesCallData[i].newContractAddressesToPass[j]
                    ]
                );

                unchecked {
                    j++;
                }
            }

            // Fill in the new bytes array with the old bytes array parameters
            for (uint256 j; j < moduleFactoriesCallData[i].data.length; ) {
                newData[
                    j + newContractAddressesToPassLength
                ] = moduleFactoriesCallData[i].data[j];

                unchecked {
                    j++;
                }
            }

            // Call the module factory with the new calldata
            (bool success, bytes memory returnData) = moduleFactoriesCallData[i]
                .factory
                .call{value: moduleFactoriesCallData[i].value}(
                abi.encodeWithSignature("create(bytes[])", newData)
            );

            if (!success) {
                revert FactoryCallFailed();
            }

            // Create an array of the returned module addresses
            address[] memory newModuleAddresses = new address[](moduleFactoriesCallData[i].addressesReturned);
            newModuleAddresses = abi.decode(returnData, (address[]));

            // Add the new module addresses to the new contract addresses array
            for(uint256 j; j < newModuleAddresses.length;) {
              newContractAddresses[newContractAddressIndex] = newModuleAddresses[j];
              unchecked {
                newContractAddressIndex++;
                j++;
              }
            }
           
            unchecked {
                i++;
            }
        }

        return newContractAddresses;
    }

    /// @notice Adds the roles and functionDescs for each newly created contract
    /// @param moduleActionData Struct of functionDescs and roles to setup for each newly created module
    /// @param newContractAddresses The array of new contract addresses
    function addActionsRoles(
        ModuleActionData memory moduleActionData,
        address[] memory newContractAddresses
    ) private {
        uint256 moduleActionTargetsLength = moduleActionData
            .contractIndexes
            .length;

        // Create address array of modules to be targeted
        address[] memory moduleActionTargets = new address[](
            moduleActionTargetsLength
        );
        for (uint256 i; i < moduleActionTargetsLength; ) {
            moduleActionTargets[i] = newContractAddresses[
                moduleActionData.contractIndexes[i]
            ];

            unchecked {
                i++;
            }
        }

        bytes memory data = abi.encodeWithSignature(
            "addActionsRoles(address[],string[],string[][])",
            moduleActionTargets,
            moduleActionData.functionDescs,
            moduleActionData.roles
        );

        address[] memory targetArray = new address[](1);
        uint256[] memory valuesArray = new uint256[](1);
        bytes[] memory dataArray = new bytes[](1);

        // Target array contains just the access control contract address
        targetArray[0] = newContractAddresses[1];
        valuesArray[0] = 0;
        dataArray[0] = data;

        // Execute the addActionRoles function on Access Control by calling through the DAO
        IDAO(newContractAddresses[0]).execute(
            targetArray,
            valuesArray,
            dataArray
        );
    }

    /// @notice Grants roles to the modules specified
    /// @param roles The array of roles to be granted to modules
    /// @param roleModuleMembers Indexes of the modules to be granted each role
    /// @param newContractAddresses Array of addresses of the newly created contracts
    function addModuleRoles(
        string[] memory roles,
        uint256[][] memory roleModuleMembers,
        address[] memory newContractAddresses
    ) private {     
        uint256 newMembersLength = roleModuleMembers.length;
        address[][] memory newMembers = new address[][](newMembersLength);
        for (uint256 i; i < newMembersLength; ) {
            uint256 newMembersInnerLength = roleModuleMembers[i].length;
            address[] memory newMembersInner = new address[](newMembersInnerLength);
            for (uint256 j; j < newMembersInnerLength; ) {
                newMembersInner[j] = newContractAddresses[
                    roleModuleMembers[i][j]
                ];
                unchecked {
                    j++;
                }
            }
            newMembers[i] = newMembersInner;
            unchecked {
                i++;
            }
        }

        bytes memory data = abi.encodeWithSignature(
            "grantRoles(string[],address[][])",
            roles,
            newMembers
        );

        address[] memory targetArray = new address[](1);
        uint256[] memory valuesArray = new uint256[](1);
        bytes[] memory dataArray = new bytes[](1);

        targetArray[0] = newContractAddresses[1];
        valuesArray[0] = 0;
        dataArray[0] = data;

        IDAO(newContractAddresses[0]).execute(
            targetArray,
            valuesArray,
            dataArray
        );
    }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IMetaFactory).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}