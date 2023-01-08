// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../../common/metadata/TokenMetadataAdminInternal.sol";
import "../../../ERC721/extensions/supply/ERC721SupplyStorage.sol";
import "../../extensions/mintable/IERC721MintableExtension.sol";
import "./IERC721MintableOwnable.sol";

/**
 * @title ERC721 - Mint as owner
 * @notice Allow minting as contract owner with no restrictions (supports ERC721A).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces IERC721MintableOwnable
 */
contract ERC721MintableOwnable is IERC721MintableOwnable, OwnableInternal, TokenMetadataAdminInternal {
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(address to, uint256 amount) public virtual onlyOwner {
        IERC721MintableExtension(address(this)).mintByFacet(to, amount);
    }

    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(address[] calldata tos, uint256[] calldata amounts) public virtual onlyOwner {
        IERC721MintableExtension(address(this)).mintByFacet(tos, amounts);
    }

    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(address[] calldata tos, uint256 amount) public virtual onlyOwner {
        IERC721MintableExtension(address(this)).mintByFacet(tos, amount);
    }

    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) public virtual onlyOwner {
        uint256 nextTokenId = ERC721SupplyStorage.layout().currentIndex;

        IERC721MintableExtension(address(this)).mintByFacet(to, amount);

        for (uint256 i = 0; i < amount; i++) {
            _setURI(nextTokenId + i, tokenURIs[i]);
        }
    }

    /**
     * @inheritdoc IERC721MintableOwnable
     */
    function mintByOwner(address[] calldata tos, string[] calldata tokenURIs) public virtual onlyOwner {
        uint256 firstTokenId = ERC721SupplyStorage.layout().currentIndex;
        uint256 total = tos.length;

        IERC721MintableExtension(address(this)).mintByFacet(tos, 1);

        for (uint256 i = 0; i < total; i++) {
            _setURI(firstTokenId + i, tokenURIs[i]);
        }
    }
}