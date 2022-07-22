// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TokenURIController } from "./IERC721TokenURIController.sol";
import { ERC721TokenURIModel } from "./ERC721TokenURIModel.sol";
import { ERC721BaseController } from "../base/ERC721BaseController.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract ERC721TokenURIController is
    IERC721TokenURIController,
    ERC721TokenURIModel,
    ERC721BaseController
{
    using AddressUtils for address;

    function ERC721TokenURI_(
        uint256 id,
        address provider,
        bool isProxyable
    ) internal virtual {
        _setTokenURIProviderInfo(id, provider, isProxyable);
        _setDefaultTokenURIProvider(id);
    }

    function tokenURI_(uint256 tokenId) internal view virtual returns (string memory) {
        uint256 providerId = tokenURIProvider_(tokenId);
        (address provider, bool isProxyable) = _tokenURIProviderInfo(providerId);

        if (isProxyable) {
            revert UnexpectedTokenURIProvider(providerId);
        }

        return _tokenURI(tokenId, provider);
    }

    function tokenURIProvider_(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256 providerId)
    {
        _enforceTokenExists(tokenId);
        providerId = _tokenURIProvider_(tokenId);
        (address provider, ) = _tokenURIProviderInfo(providerId);
        provider.enforceIsNotZeroAddress();
    }

    function tokenURIProviderInfo_(uint256 providerId)
        internal
        view
        virtual
        returns (address provider, bool isProxyable)
    {
        (provider, isProxyable) = _tokenURIProviderInfo_(providerId);
        provider.enforceIsNotZeroAddress();
    }

    function _tokenURIProvider_(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256 providerId)
    {
        providerId = _tokenURIProvider(tokenId);
        (address provider, ) = _tokenURIProviderInfo(providerId);

        if (provider == address(0)) {
            providerId = _defaultTokenURIProvider();
        }
    }

    function _tokenURIProviderInfo_(uint256 providerId)
        internal
        view
        virtual
        returns (address provider, bool isProxyable)
    {
        (provider, isProxyable) = _tokenURIProviderInfo(providerId);

        if (provider == address(0)) {
            (provider, isProxyable) = _tokenURIProviderInfo(_defaultTokenURIProvider());
        }
    }
}