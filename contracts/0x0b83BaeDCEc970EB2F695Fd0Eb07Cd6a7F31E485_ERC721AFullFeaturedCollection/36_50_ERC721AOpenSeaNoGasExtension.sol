// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "erc721a/contracts/ERC721A.sol";

import "../../../misc/opensea/ProxyRegistry.sol";

import {IERC721OpenSeaNoGasExtension} from "../../ERC721/extensions/ERC721OpenSeaNoGasExtension.sol";

/**
 * @dev Extension that automatically approves OpenSea to avoid having users to "Approve" your collection before trading.
 */
abstract contract ERC721AOpenSeaNoGasExtension is
    IERC721OpenSeaNoGasExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721A
{
    address internal _openSeaProxyRegistryAddress;
    address private _openSeaExchangeAddress;

    function __ERC721AOpenSeaNoGasExtension_init(
        address openSeaProxyRegistryAddress,
        address openSeaExchangeAddress
    ) internal onlyInitializing {
        __ERC721AOpenSeaNoGasExtension_init_unchained(
            openSeaProxyRegistryAddress,
            openSeaExchangeAddress
        );
    }

    function __ERC721AOpenSeaNoGasExtension_init_unchained(
        address openSeaProxyRegistryAddress,
        address openSeaExchangeAddress
    ) internal onlyInitializing {
        _registerInterface(type(IERC721OpenSeaNoGasExtension).interfaceId);

        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
        _openSeaExchangeAddress = openSeaExchangeAddress;
    }

    /* ADMIN */

    function setOpenSeaProxyRegistryAddress(address addr) external onlyOwner {
        _openSeaProxyRegistryAddress = addr;
    }

    function setOpenSeaExchangeAddress(address addr) external onlyOwner {
        _openSeaExchangeAddress = addr;
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721A)
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
        override(ERC721A, IERC721OpenSeaNoGasExtension)
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