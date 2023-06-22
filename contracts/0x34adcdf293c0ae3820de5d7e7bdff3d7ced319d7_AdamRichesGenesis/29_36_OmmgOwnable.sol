// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IOmmgOwnable.sol";
import "../def/CustomErrors.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

pragma solidity ^0.8.11;

abstract contract OmmgOwnable is IOmmgOwnable, Context, ERC165 {
    address private _owner;

    /// @dev Initializes the contract setting the deployer as the initial owner.
    constructor() {
        _setOwner(_msgSender());
    }

    ///@dev Reverts if called by any account other than the owner
    modifier onlyOwner() {
        if (owner() != _msgSender())
            revert OwnershipUnauthorized(_msgSender());
        _;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @dev Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner
    function renounceOwnershipPermanently() public override onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert NullAddress();
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOmmgOwnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}