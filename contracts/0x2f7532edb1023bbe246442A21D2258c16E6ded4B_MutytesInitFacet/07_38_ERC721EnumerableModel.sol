// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721EnumerablePage } from "./IERC721EnumerablePage.sol";
import { erc721EnumerableStorage, ERC721EnumerableStorage, PageInfo } from "./ERC721EnumerableStorage.sol";

abstract contract ERC721EnumerableModel {
    function _ERC721Enumerable(PageInfo[] memory pages) internal virtual {
        erc721EnumerableStorage().pages = pages;
    }

    function _tokenByIndex(uint256 index)
        internal
        view
        virtual
        returns (uint256 tokenId)
    {
        ERC721EnumerableStorage storage es = erc721EnumerableStorage();

        unchecked {
            for (uint256 i; i < es.pages.length; i++) {
                PageInfo memory page = es.pages[i];

                if (index < page.length) {
                    return IERC721EnumerablePage(page.pageAddress).tokenByIndex(index);
                }
                
                index -= page.length;
            }
        }
    }
}