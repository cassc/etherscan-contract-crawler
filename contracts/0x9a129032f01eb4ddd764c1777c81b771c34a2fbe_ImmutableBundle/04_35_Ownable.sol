// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";

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
 *
 * Modified version from openzeppelin/contracts/access/Ownable.sol that allows to
 * initialize the owner using a parameter in the constructor
 */
abstract contract Ownable is Context {
    address private _owner;

    address private _ownerCandidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /**
     * @dev Requests transferring ownership of the contract to a new account (`_newOwnerCandidate`).
     * Can only be called by the current owner.
     */
    function requestTransferOwnership(address _newOwnerCandidate) public virtual onlyOwner {
        require(_newOwnerCandidate != address(0), "Ownable: new owner is the zero address");
        _ownerCandidate = _newOwnerCandidate;
    }

    function acceptTransferOwnership() public virtual {
        require(_ownerCandidate == _msgSender(), "Ownable: not owner candidate");
        _setOwner(_ownerCandidate);
        delete _ownerCandidate;
    }

    function cancelTransferOwnership() public virtual onlyOwner {
        delete _ownerCandidate;
    }

    function rejectTransferOwnership() public virtual {
        require(_ownerCandidate == _msgSender(), "Ownable: not owner candidate");
        delete _ownerCandidate;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Sets the owner.
     */
    function _setOwner(address _newOwner) internal {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}