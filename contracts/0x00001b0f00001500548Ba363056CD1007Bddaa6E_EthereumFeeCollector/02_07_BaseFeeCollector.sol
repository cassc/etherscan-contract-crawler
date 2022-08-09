// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { TwoStepOwnable } from "../access/TwoStepOwnable.sol";

import {
    ERC20Interface,
    BaseFeeCollectorInterface
} from "../interfaces/BaseFeeCollectorInterface.sol";

import {
    BaseFeeCollectorEventsAndErrors
} from "../interfaces/BaseFeeCollectorEventsAndErrors.sol";

/**
 * @title   BaseFeeCollector
 * @author  OpenSea Protocol Team
 * @notice  BaseFeeCollector is a contract that is used as an implementation
 *          for a beacon proxy. Allows for withdrawal of the native token
 *          and all ERC20 standard tokens from the proxy. The contract
 *          inherits TwoStepOwnable to allow for ownership modifiers.
 */
contract BaseFeeCollector is
    TwoStepOwnable,
    BaseFeeCollectorInterface,
    BaseFeeCollectorEventsAndErrors
{
    // The operator address.
    address internal _operator;

    // Mapping of valid withdrawal wallets.
    mapping(address => bool) internal _withdrawalWallets;

    /**
     * @dev Throws if called by any account other than the owner or
     *      operator.
     */
    modifier isOperator() {
        if (msg.sender != _operator && msg.sender != owner()) {
            revert InvalidOperator();
        }
        _;
    }

    /**
     * @notice Creates the implementation.
     */
    constructor() {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Deployment must originate from an approved deployer."
        );
    }

    /**
     * @notice External initialization called by the proxy to set the
     *         owner. During upgrading, do not modify the original
     *         variables that were set in previous implementations.
     *
     * @param ownerToSet The address to be set as the owner.
     */
    function initialize(address ownerToSet) external {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)) &&
                owner() == address(0),
            "Initialize must originate from an approved deployer, and the owner must not be set."
        );

        // Call initialize.
        _initialize(ownerToSet);
    }

    /**
     * @notice Internal initialization function to set the owner. During
     *         upgrading, do not modify the original variables that were set
     *         in the previous implementations. Requires this call to be inside
     *         the constructor.
     *
     * @param ownerToSet The address to be set as the owner.
     */
    function _initialize(address ownerToSet) internal {
        // Set the owner of the FeeCollector.
        _setInitialOwner(ownerToSet);
    }

    /**
     * @notice Withdrawals the given amount of ERC20 tokens from the provided
     *         contract address. Requires the caller to have the operator role,
     *         and the withdrawal wallet to be in the allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param tokenContract    The ERC20 token address to be withdrawn.
     * @param amount           The amount of ERC20 tokens to be withdrawn.
     */
    function withdrawERC20Tokens(
        address withdrawalWallet,
        address tokenContract,
        uint256 amount
    ) external override isOperator {
        // Ensure the withdrawal wallet is in the withdrawal wallet mapping.
        if (_withdrawalWallets[withdrawalWallet] != true) {
            revert InvalidWithdrawalWallet(withdrawalWallet);
        }

        // Make the transfer call on the provided ERC20 token.
        (bool result, bytes memory data) = tokenContract.call(
            abi.encodeWithSelector(
                ERC20Interface.transfer.selector,
                withdrawalWallet,
                amount
            )
        );

        // Revert if we have a false result.
        if (!result) {
            revert TokenTransferGenericFailure(
                tokenContract,
                withdrawalWallet,
                0,
                amount
            );
        }

        // Revert if we have a bad return value.
        if (data.length != 0 && data.length >= 32) {
            if (!abi.decode(data, (bool))) {
                revert BadReturnValueFromERC20OnTransfer(
                    tokenContract,
                    withdrawalWallet,
                    amount
                );
            }
        }
    }

    /**
     * @notice Withdrawals the given amount of the native token from this
     *         contract to the withdrawal address. Requires the caller to
     *         have the operator role, and the withdrawal wallet to be in
     *         the allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param amount           The amount of the native token to be withdrawn.
     */
    function withdraw(address withdrawalWallet, uint256 amount)
        external
        override
        isOperator
    {
        // Ensure the withdrawal wallet is in the withdrawal wallet mapping.
        if (_withdrawalWallets[withdrawalWallet] != true) {
            revert InvalidWithdrawalWallet(withdrawalWallet);
        }

        // Ensure the amount to withdraw is valid.
        if (amount > address(this).balance) {
            revert InvalidNativeTokenAmount(amount);
        }

        // Transfer the amount of the native token to the withdrawal address.
        payable(withdrawalWallet).transfer(amount);
    }

    /**
     * @notice Adds a new withdrawal address to the mapping. Requires
     *         the caller to be the owner and the withdrawal
     *         wallet to not be the null address.
     *
     * @param newWithdrawalWallet  The new withdrawal address.
     */
    function addWithdrawAddress(address newWithdrawalWallet)
        external
        override
        onlyOwner
    {
        // Ensure the new owner is not an invalid address.
        if (newWithdrawalWallet == address(0)) {
            revert NewWithdrawalWalletIsNullAddress();
        }

        // Set the new wallet address mapping.
        _setWithdrawalWallet(newWithdrawalWallet, true);
    }

    /**
     * @notice Removes the withdrawal address from the mapping. Requires
     *         the caller to be the owner.
     *
     * @param withdrawalWallet  The withdrawal address to
     *                             remove.
     */
    function removeWithdrawAddress(address withdrawalWallet)
        external
        override
        onlyOwner
    {
        // Set the withdrawal wallet to false.
        _setWithdrawalWallet(withdrawalWallet, false);
    }

    /**
     * @notice Assign the given address with the ability to operate the wallet.
     *         Requires caller to be the owner.
     *
     * @param operatorToAssign The address to assign the operator role.
     */
    function assignOperator(address operatorToAssign)
        external
        override
        onlyOwner
    {
        // Ensure the operator to assign is not an invalid address.
        if (operatorToAssign == address(0)) {
            revert OperatorIsNullAddress();
        }

        // Set the given account as the operator.
        _operator = operatorToAssign;

        // Emit an event indicating the operator has been assigned.
        emit OperatorUpdated(_operator);
    }

    /**
     * @notice An external view function that returns a boolean.
     *
     * @return A boolean that determines if the provided address is
     *         a valid withdrawal wallet.
     */
    function isWithdrawalWallet(address withdrawalWallet)
        external
        view
        override
        returns (bool)
    {
        // Return if the wallet is in the allow list.
        return _withdrawalWallets[withdrawalWallet];
    }

    /**
     * @notice Internal function to set the withdrawal wallet mapping.
     *
     * @param withdrawalAddress The address to be set as the withdrawal
     *                          wallet.
     * @param valueToSet        The boolean to set for the mapping.
     */
    function _setWithdrawalWallet(address withdrawalAddress, bool valueToSet)
        internal
    {
        // Set the withdrawal address mapping.
        _withdrawalWallets[withdrawalAddress] = valueToSet;
    }
}