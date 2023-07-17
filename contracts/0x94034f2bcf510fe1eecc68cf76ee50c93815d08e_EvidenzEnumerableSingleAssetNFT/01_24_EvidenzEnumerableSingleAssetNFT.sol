// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';

import {ERC721Renamable} from '../token/ERC721/extensions/ERC721Renamable.sol';
import {EvidenzSingleAsset} from '../domain/EvidenzSingleAsset.sol';
import {PremintSingleAsset} from '../workflow/PremintSingleAsset.sol';

contract EvidenzEnumerableSingleAssetNFT is
    EvidenzSingleAsset,
    PremintSingleAsset,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Renamable
{
    constructor(
        string memory name_,
        string memory symbol
    ) ERC721(name_, symbol) ERC721Renamable(name_) {}

    /**
     * @dev See {ERC721-name}.
     */
    function name()
        public
        view
        virtual
        override(ERC721, ERC721Renamable)
        returns (string memory)
    {
        return super.name();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Renamable, ERC721Enumerable, EvidenzSingleAsset)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721, EvidenzSingleAsset)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}