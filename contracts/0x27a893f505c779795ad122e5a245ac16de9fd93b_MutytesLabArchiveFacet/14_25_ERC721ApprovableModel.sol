// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721ApprovableStorage as es } from "./ERC721ApprovableStorage.sol";

abstract contract ERC721ApprovableModel {
    function _approve(address approved, uint256 tokenId) internal virtual {
        es().tokenApprovals[tokenId] = approved;
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        es().operatorApprovals[owner][operator] = approved;
    }

    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return es().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return es().operatorApprovals[owner][operator];
    }
}