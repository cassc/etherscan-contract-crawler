// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721MetadataController } from "../../core/token/ERC721/metadata/ERC721MetadataController.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { ERC721BurnableController } from "../../core/token/ERC721/burnable/ERC721BurnableController.sol";
import { IntegerUtils } from "../../core/utils/IntegerUtils.sol";

abstract contract MutytesTokenController is
    ERC721BurnableController,
    ERC721MintableController,
    ERC721MetadataController
{
    using IntegerUtils for uint256;

    function MutytesToken_() internal virtual {
        ERC721Metadata_("Mutytes", "TYTE");
    }

    function _burn_(address owner, uint256 tokenId) internal virtual override {
        if (_tokenURIProvider(tokenId) != 0) {
            _setTokenURIProvider(tokenId, 0);
        }

        super._burn_(owner, tokenId);
    }

    function _maxMintBalance() internal pure virtual override returns (uint256) {
        return 10;
    }
}