// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownables is Context {
    address[2] private _owner_array;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address[2] memory owners) {
        _owner_array = owners;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function Owners() public view virtual returns (address[2] memory) {
        return _owner_array;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(
            (_owner_array[0] == _msgSender() || _owner_array[1] == _msgSender()),
            "Ownable: caller is not the owner"
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _owner_array[0] == _msgSender() ? _owner_array[0] = newOwner : _owner_array[1] = newOwner;
        emit OwnershipTransferred(_msgSender(), newOwner);
    }
}