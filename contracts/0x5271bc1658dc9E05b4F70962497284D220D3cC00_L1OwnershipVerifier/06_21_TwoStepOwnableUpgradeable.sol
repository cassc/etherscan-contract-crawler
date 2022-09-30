// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TwoStepOwnableUpgradeable
 * @notice This contract is a slightly modified version of OpenZeppelin's `OwnableUpgradeable` contract with the
 *         caveat that ownership transfer occurs in two phases. First, the current owner initiates the transfer,
 *         and then the new owner accepts it. Ownership isn't actually transferred until both steps have been
 *         completed. The purpose of this is to ensure that ownership isn't accidentally transferred to the
 *         incorrect address. Note that the initial owner account is the contract deployer by default. Also
 *         note that this contract can only be used through inheritance.
 */
abstract contract TwoStepOwnableUpgradeable is
    Initializable,
    ContextUpgradeable
{
    address private _owner;

    // A potential owner is specified by the owner when the transfer is initiated. A potential owner
    // does not have any ownership privileges until it accepts the transfer.
    address private _potentialOwner;

    /**
     * @notice Emitted when ownership transfer is initiated.
     *
     * @param owner          The current owner.
     * @param potentialOwner The address that the owner specifies as the new owner.
     */
    event OwnershipTransferInitiated(
        address indexed owner,
        address indexed potentialOwner
    );

    /**
     * @notice Emitted when ownership transfer is finalized.
     *
     * @param previousOwner The previous owner.
     * @param newOwner      The new owner.
     */
    event OwnershipTransferFinalized(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Emitted when ownership transfer is cancelled.
     *
     * @param owner                   The current owner.
     * @param cancelledPotentialOwner The previous potential owner that can no longer accept ownership.
     */
    event OwnershipTransferCancelled(
        address indexed owner,
        address indexed cancelledPotentialOwner
    );

    /**
     * @notice Initializes the contract, setting the deployer as the initial owner.
     */
    function __TwoStepOwnable_init() internal onlyInitializing {
        __TwoStepOwnable_init_unchained();
    }

    function __TwoStepOwnable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @notice Reverts if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @notice Reverts if called by any account other than the potential owner.
     */
    modifier onlyPotentialOwner() {
        _checkPotentialOwner();
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Returns the address of the potential owner.
     */
    function potentialOwner() public view virtual returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice Reverts if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(
            owner() == _msgSender(),
            "TwoStepOwnableUpgradeable: caller is not the owner"
        );
    }

    /**
     * @notice Reverts if the sender is not the potential owner.
     */
    function _checkPotentialOwner() internal view virtual {
        require(
            potentialOwner() == _msgSender(),
            "TwoStepOwnableUpgradeable: caller is not the potential owner"
        );
    }

    /**
     * @notice Initiates ownership transfer of the contract to a new account. Can only be called by
     *         the current owner.
     * @param newOwner The address that the owner specifies as the new owner.
     */
    // slither-disable-next-line external-function
    function initiateOwnershipTransfer(address newOwner)
        external
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "TwoStepOwnableUpgradeable: new owner is the zero address"
        );
        _potentialOwner = newOwner;
        emit OwnershipTransferInitiated(owner(), newOwner);
    }

    /**
     * @notice Finalizes ownership transfer of the contract to a new account. Can only be called by
     *         the account that is accepting the ownership transfer.
     */
    // slither-disable-next-line external-function
    function acceptOwnershipTransfer() public virtual onlyPotentialOwner {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Cancels the ownership transfer to the new account, keeping the current owner as is. The current
     *         owner should call this function if the transfer is initiated to the wrong address. Can only be
     *         called by the current owner.
     */
    // slither-disable-next-line external-function
    function cancelOwnershipTransfer() public virtual onlyOwner {
        require(potentialOwner() != address(0), "TwoStepOwnableUpgradeable: no existing potential owner to cancel");
        address previousPotentialOwner = _potentialOwner;
        _potentialOwner = address(0);
        emit OwnershipTransferCancelled(owner(), previousPotentialOwner);
    }

    /**
     * @notice Leaves the contract without an owner. This makes it impossible to perform any ownership
     *         functionality, including calling `onlyOwner` functions. Can only be called by the current owner.
     *         Note that renouncing ownership is a single step process.
     */
    // slither-disable-next-line external-function
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     *
     * @param newOwner The new owner of the contract.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _potentialOwner = address(0);
        emit OwnershipTransferFinalized(oldOwner, newOwner);
    }
}