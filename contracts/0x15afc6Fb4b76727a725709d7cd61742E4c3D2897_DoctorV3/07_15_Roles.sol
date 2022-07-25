// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

/**
 * @dev Uses the Ownable class and adds a second role called the minter.
 *
 * Owner: Can upload tokens, withdraw lost tokens, config ipfs hashes etc. Can also mint tokens.
     Can set the other roles.
 * Minter: Can only mint tokens.
 * Doctor: If set, can diagnose pieces. Replaces the builtin rand gen.
 */
abstract contract Roles is Context, Ownable {
    address private _minter;
    address private _doctor;

    /**
     * @dev Initializes the contract setting the deployer as the initial minter.
     */
    constructor () {
        address msgSender = _msgSender();
        _minter = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current minter.
     */
    function minter() public view returns (address) {
        return _minter;
    }

    /**
     * @dev Returns the address of the doctor.
     */
    function doctor() public view returns (address) {
        return _doctor;
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(_minter == _msgSender(), "not minter");
        _;
    }

    /**
     * @dev Throws if called by any account other than the doctor.
     */
    modifier onlyDoctor() {
        require(_doctor == _msgSender(), "not doctor");
        _;
    }

    /**
     * @dev Throws if called by any account other than the minter or the owner.
     */
    modifier onlyMinterOrOwner() {
        require(_minter == _msgSender() || owner() == _msgSender(), "not minter or owner");
        _;
    }

    /**
     * @dev Transfers the minter role of the contract to a new account (`newMinter`).
     * Can only be called by the owner.
     */
    function setMinter(address newMinter) public virtual onlyOwner {
        require(newMinter != address(0), "zero address");
        _minter = newMinter;
    }

    /**
     * @dev Assigns the doctor role, replacing the builtin rng.
     */
    function setDoctor(address newDoctor) public virtual onlyOwner {
        require(newDoctor != address(0), "zero address");
        _doctor = newDoctor;
    }
}