// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";

// Requried one small change in openzeppelin version of ownable, so imported
// source code here. Notice line 26 for change.

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    /**
     * @dev Changed _owner from 'private' to 'internal'
     */
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module extends Ownable and provide a way for safe transfer ownership.
 * Proposed owner has to call acceptOwnership in order to complete ownership trasnfer.
 */
contract Owned is Ownable {
    address private _proposedOwner;

    /**
     * @dev Initiate transfer ownership of the contract to a new account (`proposedOwner`).
     * Can only be called by the current owner. Current owner will still be owner until
     * proposed owner accept ownership.
     * @param proposedOwner proposed owner address
     */
    function transferOwnership(address proposedOwner) public override onlyOwner {
        //solhint-disable-next-line reason-string
        require(proposedOwner != address(0), "Proposed owner is the zero address");
        _proposedOwner = proposedOwner;
    }

    /// @dev Allows proposed owner to accept ownership of the contract.
    function acceptOwnership() public {
        require(msg.sender == _proposedOwner, "Caller is not the proposed owner");
        emit OwnershipTransferred(_owner, _proposedOwner);
        _owner = _proposedOwner;
        _proposedOwner = address(0);
    }

    function renounceOwnership() public override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _proposedOwner = address(0);
    }
}