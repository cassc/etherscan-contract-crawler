// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import {Action, IERC5050Receiver, IERC5050Sender} from "../../interfaces/IERC5050.sol";
import {ActionsSet} from "../../common/ActionsSet.sol";

/// @title ERC-5050 Proxy Registry
///  Note: the ERC-165 identifier for this interface is 0x01ffc9a7
interface IERC5050RegistryClient {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Query if an address implements an interface and through which contract.
    /// @param _addr Address being queried for the implementer of an interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @return The address of the contract which implements the interface '_interfaceHash' for '_addr'
    /// or '0' if '_addr' did not register an implementer for this interface.
    function getInterfaceImplementer(address _addr, bytes4 _interfaceHash) external view returns (address);
}

library ERC5050StateStorage {
    using ActionsSet for ActionsSet.Set;

    bytes32 constant ERC_5050_STORAGE_POSITION =
        keccak256("erc5050.storage.location");
    IERC5050RegistryClient constant ERC_5050_PROXY_REGISTRY = 
        IERC5050RegistryClient(0x5050f71E270671315B460F5C4C37A82deAE6F77D);

    struct Layout {
        IERC5050RegistryClient proxyRegistry;
        bool proxyDisabled;
        ActionsSet.Set _receivableActions;
        mapping(address => mapping(bytes4 => bool)) _actionControllers;
        mapping(address => bool) _universalControllers;
        uint256 receiverLock;
    }

    function layout() internal pure returns (Layout storage es) {
        bytes32 position = ERC_5050_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function getProxyRegistry() internal view returns (IERC5050RegistryClient) {
        Layout storage store = layout();
        if(address(store.proxyRegistry) == address(0) && !store.proxyDisabled){
            return ERC_5050_PROXY_REGISTRY;
        }
        return store.proxyRegistry;
    }
    
    function getReceiverProxy(address _addr) internal view returns (address) {
        IERC5050RegistryClient proxyRegistry = getProxyRegistry();
        if(address(proxyRegistry) == address(0)){
            return _addr;
        }
        if(_addr == address(0)) {
            return _addr;
        }
        return proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Receiver).interfaceId);
    }
    
    function getSenderProxy(address _addr) internal view returns (address) {
        IERC5050RegistryClient proxyRegistry = getProxyRegistry();
        if(address(proxyRegistry) == address(0)){
            return _addr;
        }
        if(_addr == address(0)) {
            return _addr;
        }
        return proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Sender).interfaceId);
    }
    
    function setProxyRegistry(address _addr) internal {
        layout().proxyRegistry = IERC5050RegistryClient(_addr);
    }
}