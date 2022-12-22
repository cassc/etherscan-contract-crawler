// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';
import './interfaces/IOwnable.sol';

abstract contract Ownable is Context, IOwnable {
    address private _ownerAddress;

    constructor(address ownerAddress) {
        _transferOwnership(ownerAddress);
    }

    modifier onlyOwner() virtual {
        if (_msgSender() != owner()) revert SenderIsNotOwner();
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        if (newOwner == address(0)) revert RecipientAddressIsZeroAddress();

        _transferOwnership(newOwner);
    }

    function owner() public view virtual override returns (address) {
        return _ownerAddress;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _ownerAddress;
        _ownerAddress = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}