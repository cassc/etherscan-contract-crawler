// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../interface/IERC173.sol";
import "../interface/errors/IERC173Errors.sol";

contract Owner is IERC173, IERC173Errors {
    address private _owner;
    address private _getApprovedOwner;

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier ownership() {
        if (owner() != msg.sender) {
            revert NonOwnership(owner(), msg.sender);
        }
        _;
    }

    function owner() public view virtual override(IERC173) returns (address) {
        return _owner;
    }

    function transferOwnership(address _to)
        public
        virtual
        override(IERC173)
        ownership
    {
        if (_to == address(0)) {
            revert TransferOwnershipToZeroAddress(owner(), _to);
        }
        _transferOwnership(_to);
    }

    function approveOwnership(address _approved) public virtual ownership {
        _getApprovedOwner = _approved;
    }

    function getApprovedOwner() public view virtual returns (address) {
        return _getApprovedOwner;
    }

    function _isApprovedOwnerOrOwnership(address _address)
        internal
        view
        virtual
        returns (bool)
    {
        return _getApprovedOwner == _address || _owner == _address;
    }

    function _transferOwnership(address _to) internal virtual {
        address _from = _owner;
        _owner = _to;
        emit OwnershipTransferred(_from, _to);
    }
}