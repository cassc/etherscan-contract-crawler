// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

/// Implements Ownable with a two step transfer of ownership
abstract contract Ownable is Context {
    address private _owner;
    address private _proposedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Proposes a transfer of ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _proposedOwner = newOwner;
    }

    /**
     * @dev Accepts ownership of the contract by a proposed account.
     * Can only be called by the proposed owner.
     */
    function acceptOwnership() public virtual {
        require(msg.sender == _proposedOwner, "Ownable: Only proposed owner can accept ownership");
        _setOwner(_proposedOwner);
        _proposedOwner = address(0);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}