// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TokenURIProvider } from "./IERC721TokenURIProvider.sol";
import { erc721TokenURIStorage as es, ProviderInfo } from "./ERC721TokenURIStorage.sol";

abstract contract ERC721TokenURIModel {
    function _ERC721TokenURI(
        uint256 id,
        address provider,
        bool isProxyable
    ) internal virtual {
        _setTokenURIProviderInfo(id, provider, isProxyable);
        _setDefaultTokenURIProvider(id);
    }

    function _tokenURI(uint256 tokenId, address provider)
        internal
        view
        virtual
        returns (string memory)
    {
        return IERC721TokenURIProvider(provider).tokenURI(tokenId);
    }

    function _setTokenURIProvider(uint256 tokenId, uint256 providerId) internal virtual {
        es().tokenURIProviders[tokenId] = providerId;
    }

    function _setTokenURIProviderInfo(
        uint256 providerId,
        address providerAddress,
        bool isProxyable
    ) internal virtual {
        es().providerInfo[providerId] = ProviderInfo(isProxyable, providerAddress);
    }

    function _setDefaultTokenURIProvider(uint256 providerId) internal virtual {
        es().defaultProvider = providerId;
    }

    function _tokenURIProvider(uint256 tokenId) internal view virtual returns (uint256) {
        return es().tokenURIProviders[tokenId];
    }

    function _tokenURIProviderInfo(uint256 providerId)
        internal
        view
        virtual
        returns (address, bool)
    {
        ProviderInfo memory providerInfo = es().providerInfo[providerId];
        return (providerInfo.providerAddress, providerInfo.isProxyable);
    }

    function _defaultTokenURIProvider() internal view virtual returns (uint256) {
        return es().defaultProvider;
    }
}