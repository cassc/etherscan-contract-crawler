// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";

/**
 * @title ERC721DefaultApproval
 * ERC721DefaultApproval - This contract manages the default approval for ERC721.
 */
abstract contract ERC721DefaultApproval is ERC721Upgradeable {
    mapping(address => bool) private _defaultApprovals;

    event DefaultApprovalSet(address indexed operator, bool indexed status);

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _defaultApprovals[operator] ||
            super.isApprovedForAll(owner, operator);
    }

    function _setDefaultApproval(address operator, bool status) internal {
        require(
            _defaultApprovals[operator] != status,
            "DefaultApproval: default approval already set"
        );
        _defaultApprovals[operator] = status;
        emit DefaultApprovalSet(operator, status);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return
            _defaultApprovals[spender] ||
            super._isApprovedOrOwner(spender, tokenId);
    }

    uint256[50] private __gap;
}