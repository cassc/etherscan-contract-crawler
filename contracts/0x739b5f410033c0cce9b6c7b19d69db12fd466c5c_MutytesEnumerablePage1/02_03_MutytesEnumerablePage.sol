// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721EnumerablePage } from "../../core/token/ERC721/enumerable/IERC721EnumerablePage.sol";

/**
 * @title ERC721 enumerable page implementation
 * @dev Every token id should be 21 bytes long
 */
abstract contract MutytesEnumerablePage is IERC721EnumerablePage {
    /**
     * @inheritdoc IERC721EnumerablePage
     */
    function tokenByIndex(uint256 index) external view virtual returns (uint256 tokenId) {
        bytes memory bytecode = _bytecode();
        uint256 pos = (index + 1) * 21;
        
        assembly {
            tokenId := and(mload(add(bytecode, pos)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function _bytecode() internal view virtual returns (bytes memory);
}