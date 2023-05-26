// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";
import {AccessControlEnumerable, BaseSellable} from "./BaseSellable.sol";

/**
 * @notice Base contract for sellable ERC721ACommon tokens.
 */
abstract contract SellableERC721ACommon is BaseSellable, ERC721ACommon {
    /**
     * @inheritdoc BaseSellable
     */
    function _handleSale(address to, uint64 num, bytes calldata) internal virtual override {
        _mint(to, num);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, AccessControlEnumerable)
        returns (bool)
    {
        return ERC721ACommon.supportsInterface(interfaceId) || AccessControlEnumerable.supportsInterface(interfaceId);
    }
}