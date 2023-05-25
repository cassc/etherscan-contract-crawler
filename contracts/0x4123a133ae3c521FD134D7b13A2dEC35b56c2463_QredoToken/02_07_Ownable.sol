// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () public {
        address msgSender = _msgSender();
        require(msgSender != address(0), "Ownable:constructor:msgSender zero address");
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
        * @dev Returns the address of the current owner.
    */
    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
        * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable::onlyOwner:caller is not the owner");
        _;
    }

    /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable::transferOwnership:new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}