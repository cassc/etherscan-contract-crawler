// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IOwnable.sol";

/**
 * see openzeppelin/contracts/access/Ownable.sol
 * doc modification to inherit owner of parent, initializable
 */
abstract contract InheritedOwner is Context, IOwnable {
    address private _parent;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initializeInheritedOwner(address parent_)
        internal
    {
        require(_parent == address(0), 'InheritedOwner: initialized yet');
        require(parent_ != address(0), 'InheritedOwner: parent is null');

        _parent = parent_;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner()
        override virtual
        public view
        returns (address)
    {
        return IOwnable(_parent).owner();
    }

    function parent()
        public view
        returns (address)
    {
        return _parent;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}