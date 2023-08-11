// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "../../../misc/opensea/ProxyRegistry.sol";

interface ERC721OpenSeaNoGasExtensionInterface {
    function setOpenSeaProxyRegistryAddress(address addr) external;

    function setOpenSeaExchangeAddress(address addr) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

/**
 * @dev Extension that automatically approves OpenSea to avoid having users to "Approve" your collection before trading.
 */
abstract contract ERC721OpenSeaNoGasExtension is
    Ownable,
    ERC165Storage,
    ERC721,
    ERC721OpenSeaNoGasExtensionInterface
{
    address internal _openSeaProxyRegistryAddress;
    address private _openSeaExchangeAddress;

    constructor(
        address openSeaProxyRegistryAddress,
        address openSeaExchangeAddress
    ) {
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
        _openSeaExchangeAddress = openSeaExchangeAddress;

        _registerInterface(
            type(ERC721OpenSeaNoGasExtensionInterface).interfaceId
        );
    }

    // ADMIN

    function setOpenSeaProxyRegistryAddress(address addr) external onlyOwner {
        _openSeaProxyRegistryAddress = addr;
    }

    function setOpenSeaExchangeAddress(address addr) external onlyOwner {
        _openSeaExchangeAddress = addr;
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721, ERC721OpenSeaNoGasExtensionInterface)
        returns (bool)
    {
        if (_openSeaProxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(
                _openSeaProxyRegistryAddress
            );

            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        if (_openSeaExchangeAddress != address(0)) {
            // If OpenSea's ERC721 exchange address is detected, auto-approve
            if (operator == address(_openSeaExchangeAddress)) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }
}