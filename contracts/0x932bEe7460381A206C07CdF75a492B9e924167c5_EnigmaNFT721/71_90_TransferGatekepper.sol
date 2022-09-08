// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITransferGatekeeper.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IWhitelistHandler.sol";
import "../interfaces/IWyvernProxyRegistry.sol";

/// @title TransferGatekeeper
///
/// @dev This contract abstracts the transfer gatekeeping implementation to the caller, ie, ERC721 & ERC1155 tokens
///			 The logic can be replaced and the `canTransfer` will invoke the proper target function. It's important
///			 to mention that no storage is shared between this contract and the corresponding implementation
///			 call is used instead of delegate call to avoid different implementations storage compatibility.
contract TransferGatekeeper is ITransferGatekeeper, IWhitelistHandler, Ownable {
    event WhitelistChanged(address indexed _oldImplementation, address indexed _newImplementation);
    event RegistryChanged(address indexed _oldImplementation, address indexed _newImplementation);

    // The address of the whitelist implementation
    IWhitelist public whitelist;

    // The Wyvern compatible registry on wich to very user-proxy
    IWyvernProxyRegistry public registry;

    // Allowd the owner to enable/disable the registry
    bool public useRegistry;

    constructor(IWhitelist _whitelist) {
        require(address(_whitelist) != address(0), "invalid address");
        whitelist = _whitelist;
        useRegistry = false;
    }

    /**
        @notice Legacy function to support retrocompatibility on migration
                from WhitelistProxy to TransferGatekeeper
     */
    function canTransfer(address _proxy) external view returns (bool) {
        return whitelist.canTransfer(_proxy);
    }

    /**
     * @inheritdoc ITransferGatekeeper
     */
    function canTransfer(
        address _from,
        address,
        address _proxy,
        bytes memory
    ) external view override returns (bool) {
        return
            _from == _proxy || // the owner is executing the transfer
            whitelist.canTransfer(_proxy) || // the executor is whitelisted
            canTransferFromProxy(_from, _proxy); // the executor is an authorized proxy
    }

    function canTransferFromProxy(address _from, address _proxy) internal view returns (bool) {
        if (!useRegistry || address(registry) == address(0)) return false;
        address registryProxy = registry.proxies(_from);
        return address(registryProxy) == _proxy;
    }

    /**
     * @notice Sets the new address on wich to check whitelisting and enables its use
     * @param _registry the address of the new proxy registry implementation
     */
    function setRegistry(IWyvernProxyRegistry _registry) external onlyOwner {
        require(address(_registry) != address(0), "setRegistry: invalid address");
        emit RegistryChanged(address(registry), address(_registry));
        registry = _registry;
        setUseRegistry(true);
    }

    /**
     * @notice Enables/disable the registry use
     * @param _useRegistry true if you want to enable it
     */
    function setUseRegistry(bool _useRegistry) public onlyOwner {
        require(address(registry) != address(0), "Cannot change registry use with empty address");
        useRegistry = _useRegistry;
    }

    /**
     * @notice Sets the new address on wich to check whitelisting
     * @param _whitelist the address of the new whitelist implementation
     */
    function setWhitelist(IWhitelist _whitelist) external override onlyOwner {
        require(address(_whitelist) != address(0), "updateWhitelist: invalid address");
        emit WhitelistChanged(address(whitelist), address(_whitelist));
        whitelist = _whitelist;
    }
}