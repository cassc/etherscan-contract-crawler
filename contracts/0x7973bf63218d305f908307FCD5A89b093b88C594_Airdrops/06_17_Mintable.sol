// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an minter) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the minter account will be the one that deploys the contract. This
 * can later be changed with {setMinter}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMinter`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Mintable is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    // Track registered minters
    EnumerableSet.AddressSet private _minters;

    /**
     * @dev Initializes the contract setting the deployer as the initial minter.
     */
    constructor() {
    }

    /**
     * @dev Returns the address of the current minters.
     */
    function getMinters() external view returns (address[] memory minters) {
        minters = new address[](_minters.length());
        for (uint i = 0; i < _minters.length(); i++) {
            minters[i] = _minters.at(i);
        }
        return minters;
    }

    /**
     * @dev Throws if called by any account other than the Minter.
     */
    modifier onlyMinter() {
        require(owner() == _msgSender() || _minters.contains(msg.sender), "Mintable: caller is not the owner or minter");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function addMinter(address newMinter) external virtual onlyOwner {
        require(newMinter != address(0), "Mintable: new minter is the zero address.");
        require(!_minters.contains(newMinter),"Mintable: Minter already exists.");
        _addMinter(newMinter);
    }
    
    /**
     * @dev Revoke a minter
     */
    function revokeMinter(address minter) external onlyOwner {
        if (_minters.contains(minter)) {
            _minters.remove(minter);
        }
    }

    function _addMinter(address newMinter) private {
        _minters.add(newMinter);
    }
}