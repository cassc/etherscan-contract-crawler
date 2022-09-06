// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IErrors.sol";
import "../interfaces/IERC173.sol";

/**
 * @dev Implementation of the ERC173 standard
 */
contract Master is
    IERC173,
    IErrors {

    // Master address of contract variable
    address private _master;

    /**
     * @dev Modifier for ownership access
     */
    modifier master(
    ) {
        if (
            owner() != msg.sender
        ) {
            revert CallerIsNonContractOwner();
        }
        _;
    }

    /**
     * @dev Constructs master role
     */
    constructor(
        address owner_
    ) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns master of contract
     */
    function owner(
    ) public view override(
        IERC173
    ) returns (address) {
        return _master;
    }

    /**
     * @dev Prevents role transfer to zero address
     */
    function transferOwnership(
        address _newOwner
    ) public override(
        IERC173
    ) master {
        if (
            _newOwner == address(0)
        ) {
            revert TransferToZeroAddress();
        }
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Master role transfer
     */
    function _transferOwnership(
        address _newOwner
    ) internal {
        address previousOwner = _master;
        _master = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}