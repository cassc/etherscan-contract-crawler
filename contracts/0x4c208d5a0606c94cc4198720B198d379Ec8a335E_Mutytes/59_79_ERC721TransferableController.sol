// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TransferableController } from "./IERC721TransferableController.sol";
import { ERC721TransferableModel } from "./ERC721TransferableModel.sol";
import { ERC721ApprovableController } from "../approvable/ERC721ApprovableController.sol";
import { ERC721ReceiverUtils } from "../utils/ERC721ReceiverUtils.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract ERC721TransferableController is
    IERC721TransferableController,
    ERC721TransferableModel,
    ERC721ApprovableController
{
    using ERC721ReceiverUtils for address;
    using AddressUtils for address;

    function safeTransferFrom_(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        if (to.isContract()) {
            to.enforceNotEquals(from);
            _enforceCanTransferFrom(from, to, tokenId);
            _transferFrom_(from, to, tokenId);
            to.enforceOnReceived(msg.sender, from, tokenId, data);
        } else {
            transferFrom_(from, to, tokenId);
        }
    }

    function transferFrom_(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        to.enforceIsNotZeroAddress();
        to.enforceNotEquals(from);
        _enforceCanTransferFrom(from, to, tokenId);
        _transferFrom_(from, to, tokenId);
    }

    function _transferFrom_(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (_getApproved(tokenId) != address(0)) {
            _approve_(from, address(0), tokenId);
        }

        _transferFrom(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _enforceCanTransferFrom(
        address from,
        address,
        uint256 tokenId
    ) internal view virtual {
        from.enforceEquals(_ownerOf(tokenId));
        _enforceIsApproved(from, msg.sender, tokenId);
    }
}