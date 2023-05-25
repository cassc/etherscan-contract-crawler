// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {ERC721A, ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";
import {RedeemableERC721ACommon} from "./RedeemableERC721ACommon.sol";
import {
    TransferRestriction,
    ERC721ATransferRestrictedBase,
    ERC721ATransferRestricted
} from "../restricted/ERC721ATransferRestricted.sol";

/**
 * @notice An ERC721 token intended to act as freely tradeable voucher.
 * @dev This is mainly a convenience wrapper.
 */
abstract contract TransferRestrictedRedeemableERC721ACommon is RedeemableERC721ACommon, ERC721ATransferRestricted {
    /**
     * @notice Overrides supportsInterface as required by inheritance.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RedeemableERC721ACommon, ERC721ACommon)
        returns (bool)
    {
        return RedeemableERC721ACommon.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721ATransferRestrictedBase
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override(ERC721ATransferRestrictedBase, ERC721ACommon)
    {
        ERC721ATransferRestrictedBase._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}