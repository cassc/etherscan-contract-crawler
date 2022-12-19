// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an reciver) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the reciver account will be the one that deploys the contract. This
 * can later be changed with {transferRecivership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyReciver`, which can be applied to your functions to restrict their use to
 * the reciver.
 */
abstract contract Reciver is Context {
    address private _reciver;

    event RecivershipTransferred(address indexed previousReciver, address indexed newReciver);

    /**
     * @dev Initializes the contract setting the deployer as the initial reciver.
     */
    constructor(address reciver_) {
        _transferRecivership(reciver_);
    }

    /**
     * @dev Returns the address of the current reciver.
     */
    function reciver() public view virtual returns (address) {
        return _reciver;
    }

    /**
     * @dev Throws if called by any account other than the reciver.
     */
    modifier onlyReciver() {
        require(reciver() == _msgSender(), "Ownable: caller is not the reciver");
        _;
    }

    /**
     * @dev Leaves the contract without reciver. It will not be possible to call
     * `onlyReciver` functions anymore. Can only be called by the current reciver.
     *
     * NOTE: Renouncing recivership will leave the contract without an reciver,
     * thereby removing any functionality that is only available to the reciver.
     */
    function renounceRecivership() public virtual onlyReciver {
        _transferRecivership(address(0));
    }

    /**
     * @dev Transfers recivership of the contract to a new account (`newReciver`).
     * Can only be called by the current reciver.
     */
    function transferRecivership(address newReciver) public virtual onlyReciver {
        require(newReciver != address(0), "Ownable: new reciver is the zero address");
        _transferRecivership(newReciver);
    }

    /**
     * @dev Transfers recivership of the contract to a new account (`newReciver`).
     * Internal function without access restriction.
     */
    function _transferRecivership(address newReciver) internal virtual {
        address oldReciver = _reciver;
        _reciver = newReciver;
        emit RecivershipTransferred(oldReciver, newReciver);
    }
}