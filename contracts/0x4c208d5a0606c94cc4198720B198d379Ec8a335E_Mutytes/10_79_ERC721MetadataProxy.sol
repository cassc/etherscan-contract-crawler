// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Metadata } from "./IERC721Metadata.sol";
import { ERC721MetadataController } from "./ERC721MetadataController.sol";
import { ERC721TokenURIProxyController } from "../tokenURI/ERC721TokenURIProxyController.sol";
import { ProxyUpgradableController } from "../../../proxy/upgradable/ProxyUpgradableController.sol";

/**
 * @title ERC721 metadata extension implementation
 * @dev Note: Upgradable implementation
 */
abstract contract ERC721MetadataProxy is
    IERC721Metadata,
    ERC721MetadataController,
    ERC721TokenURIProxyController,
    ProxyUpgradableController
{
    /**
     * @inheritdoc IERC721Metadata
     */
    function name() external virtual upgradable returns (string memory) {
        return name_();
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() external virtual upgradable returns (string memory) {
        return symbol_();
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        external
        virtual
        upgradable
        returns (string memory)
    {
        return tokenURIProxyable_(tokenId);
    }
}