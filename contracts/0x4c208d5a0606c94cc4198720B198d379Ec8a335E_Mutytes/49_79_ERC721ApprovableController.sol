// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721ApprovableController } from "./IERC721ApprovableController.sol";
import { ERC721ApprovableModel } from "./ERC721ApprovableModel.sol";
import { ERC721BaseController } from "../base/ERC721BaseController.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract ERC721ApprovableController is
    IERC721ApprovableController,
    ERC721ApprovableModel,
    ERC721BaseController
{
    using AddressUtils for address;

    function approve_(address approved, uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);
        owner.enforceNotEquals(approved);
        _enforceIsApproved(owner, msg.sender);
        _approve_(owner, approved, tokenId);
    }

    function setApprovalForAll_(address operator, bool approved) internal virtual {
        operator.enforceIsNotZeroAddress();
        operator.enforceNotEquals(msg.sender);
        _setApprovalForAll_(msg.sender, operator, approved);
    }

    function getApproved_(uint256 tokenId) internal view virtual returns (address) {
        _enforceTokenExists(tokenId);
        return _getApproved(tokenId);
    }

    function isApprovedForAll_(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return _isApprovedForAll(owner, operator);
    }

    function _approve_(
        address owner,
        address approved,
        uint256 tokenId
    ) internal virtual {
        _approve(approved, tokenId);
        emit Approval(owner, approved, tokenId);
    }

    function _setApprovalForAll_(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        _setApprovalForAll(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    function _isApproved(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return owner == operator || _isApprovedForAll(owner, operator);
    }

    function _isApproved(
        address owner,
        address operator,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        return _isApproved(owner, operator) || _getApproved(tokenId) == operator;
    }

    function _enforceIsApproved(address owner, address operator) internal view virtual {
        if (!_isApproved(owner, operator)) {
            revert UnapprovedOperatorAction();
        }
    }

    function _enforceIsApproved(
        address owner,
        address operator,
        uint256 tokenId
    ) internal view virtual {
        if (!_isApproved(owner, operator, tokenId)) {
            revert UnapprovedTokenAction(tokenId);
        }
    }
}