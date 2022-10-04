//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IExtendLogic.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";
import {RoleState, Permissions} from "../../storage/PermissionStorage.sol";
import "../../erc165/IERC165Logic.sol";
import "../permissioning/IPermissioningLogic.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Reference implementation for ExtendLogic which defines the logic to extend
 *      Extendable contracts
 *
 * Uses PermissioningLogic owner pattern to control extensibility. Only the `owner`
 * can extend using this logic.
 *
 * Modify this ExtendLogic extension to change the way that your contract can be
 * extended: public extendability; DAO-based extendability; governance-vote-based etc.
*/
contract ExtendLogic is ExtendExtension {
    /**
     * @dev see {Extension-constructor} for constructor
    */

    /**
     * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner` or the current contract
    */
    modifier onlyOwnerOrSelf virtual {
        initialise();
    
        address owner = Permissions._getState().owner;
        require(_lastCaller() == owner || _lastCaller() == address(this), "unauthorised");
        _;
    }

    /**
     * @dev see {IExtendLogic-extend}
     *
     * Uses PermissioningLogic implementation with `owner` checks.
     *
     * Restricts extend to `onlyOwnerOrSelf`.
     *
     * If `owner` has not been initialised, assume that this is the initial extend call
     * during constructor of Extendable and instantiate `owner` as the caller.
     *
     * If any single function in the extension has already been extended by another extension,
     * revert the transaction.
    */
    function extend(address extension) override public virtual onlyOwnerOrSelf {
        require(extension.code.length > 0, "Extend: address is not a contract");

        IERC165 erc165Extension = IERC165(extension);
        try erc165Extension.supportsInterface(bytes4(0x01ffc9a7)) returns(bool erc165supported) {
            require(erc165supported, "Extend: extension does not implement eip-165");
            require(erc165Extension.supportsInterface(type(IExtension).interfaceId), "Extend: extension does not implement IExtension");
        } catch (bytes memory) {
            revert("Extend: extension does not implement eip-165");
        }

        IExtension ext = IExtension(payable(extension));

        Interface[] memory interfaces = ext.getInterface();
        registerInterfaces(interfaces, extension);

        emit Extended(extension);
    }

    /**
     * @dev see {IExtendLogic-getFullInterface}
    */
    function getFullInterface() override public view returns(string memory fullInterface) {
        ExtendableState storage state = ExtendableStorage._getState();
        uint numberOfInterfacesImplemented = state.implementedInterfaceIds.length;

        // collect unique extension addresses
        address[] memory extensions = new address[](numberOfInterfacesImplemented);
        uint numberOfUniqueExtensions;
        for (uint i = 0; i < numberOfInterfacesImplemented; i++) {
            bytes4 interfaceId = state.implementedInterfaceIds[i];
            address extension = state.extensionContracts[interfaceId];

            // if we have seen this extension before, ignore and continue looping
            if (i != 0 && exists(extension, extensions, numberOfUniqueExtensions)) continue;
            extensions[numberOfUniqueExtensions] = extension;
            numberOfUniqueExtensions++;
            
            IExtension logic = IExtension(extension);
            fullInterface = string(abi.encodePacked(fullInterface, logic.getSolidityInterface()));
        }

        // TO-DO optimise this return to a standardised format with comments for developers
        return string(abi.encodePacked("interface IExtended {\n", fullInterface, "}"));
    }

    /**
     * @dev see {IExtendLogic-getExtensionsInterfaceIds}
    */
    function getExtensionsInterfaceIds() override public view returns(bytes4[] memory) {
        ExtendableState storage state = ExtendableStorage._getState();
        return state.implementedInterfaceIds;
    }

    /**
     * @dev see {IExtendLogic-getExtensionsFunctionSelectors}
    */
    function getExtensionsFunctionSelectors() override public view returns(bytes4[] memory functionSelectors) {
        ExtendableState storage state = ExtendableStorage._getState();
        bytes4[] storage implementedInterfaces = state.implementedInterfaceIds;
        
        uint256 numberOfFunctions = 0;
        for (uint256 i = 0; i < implementedInterfaces.length; i++) {
                numberOfFunctions += state.implementedFunctionsByInterfaceId[implementedInterfaces[i]].length;
        }

        functionSelectors = new bytes4[](numberOfFunctions);
        uint256 counter = 0;
        for (uint256 i = 0; i < implementedInterfaces.length; i++) {
            uint256 functionNumber = state.implementedFunctionsByInterfaceId[implementedInterfaces[i]].length;
            for (uint256 j = 0; j < functionNumber; j++) {
                functionSelectors[counter] = state.implementedFunctionsByInterfaceId[implementedInterfaces[i]][j];
                counter++;
            }
        }
    }

    /**
     * @dev see {IExtendLogic-getExtensionAddresses}
    */
    function getExtensionAddresses() override public view returns(address[] memory) {
        ExtendableState storage state = ExtendableStorage._getState();
        uint numberOfInterfacesImplemented = state.implementedInterfaceIds.length;

        // collect unique extension addresses
        address[] memory extensions = new address[](numberOfInterfacesImplemented);
        uint numberOfUniqueExtensions;
        for (uint i = 0; i < numberOfInterfacesImplemented; i++) {
            bytes4 interfaceId = state.implementedInterfaceIds[i];
            address extension = state.extensionContracts[interfaceId];

            if (i != 0 && exists(extension, extensions, numberOfUniqueExtensions)) continue;
            extensions[numberOfUniqueExtensions] = extension;
            numberOfUniqueExtensions++;
        }

        address[] memory uniqueExtensions = new address[](numberOfUniqueExtensions);
        for (uint i = 0; i < numberOfUniqueExtensions; i++) {
            uniqueExtensions[i] = extensions[i];
        }

        return uniqueExtensions;
    }

    function exists(address item, address[] memory addresses, uint256 untilIndex) internal pure returns(bool) {
        for (uint i = 0; i < untilIndex; i++) {
            if (addresses[i] == item) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Sets the owner of the contract to the tx origin if unset
     *
     * Used by Extendable during first extend to set deployer as the owner that can
     * extend the contract
    */
    function initialise() internal {
        RoleState storage state = Permissions._getState();

        // Set the owner to the transaction sender if owner has not been initialised
        if (state.owner == address(0x0)) {
            state.owner = _lastCaller();
            emit OwnerInitialised(_lastCaller());
        }
    }

    function registerInterfaces(Interface[] memory interfaces, address extension) internal {
        ExtendableState storage state = ExtendableStorage._getState();

        // Record each interface as implemented by new extension, revert if a function is already implemented by another extension
        uint256 numberOfInterfacesImplemented = interfaces.length;
        for (uint256 i = 0; i < numberOfInterfacesImplemented; i++) {
            bytes4 interfaceId = interfaces[i].interfaceId;
            address implementer = state.extensionContracts[interfaceId];

            require(
                implementer == address(0x0),
                string(abi.encodePacked("Extend: interface ", Strings.toHexString(uint256(uint32(interfaceId)), 4)," is already implemented by ", Strings.toHexString(implementer)))
            );

            registerFunctions(interfaceId, interfaces[i].functions, extension);
            state.extensionContracts[interfaceId] = extension;
            state.implementedInterfaceIds.push(interfaceId);

            if (interfaceId == type(IExtendLogic).interfaceId) {
                state.extensionContracts[type(IERC165).interfaceId] = extension;
                state.extensionContracts[type(IERC165Register).interfaceId] = extension;
            }
        }
    }

    function registerFunctions(bytes4 interfaceId, bytes4[] memory functionSelectors, address extension) internal {
        ExtendableState storage state = ExtendableStorage._getState();

        // Record each function as implemented by new extension, revert if a function is already implemented by another extension
        uint256 numberOfFunctions = functionSelectors.length;
        for (uint256 i = 0; i < numberOfFunctions; i++) {
            address implementer = state.extensionContracts[functionSelectors[i]];

            require(
                implementer == address(0x0),
                string(abi.encodePacked("Extend: function ", Strings.toHexString(uint256(uint32(functionSelectors[i])), 4)," is already implemented by ", Strings.toHexString(implementer)))
            );

            state.extensionContracts[functionSelectors[i]] = extension;
            state.implementedFunctionsByInterfaceId[interfaceId].push(functionSelectors[i]);
        }
    }
}