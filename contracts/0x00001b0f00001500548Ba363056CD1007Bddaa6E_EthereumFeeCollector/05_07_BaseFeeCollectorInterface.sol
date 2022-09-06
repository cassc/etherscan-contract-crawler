// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20Interface {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

/**
 * @title   BaseFeeCollectorInterface
 * @author  OpenSea Protocol Team
 * @notice  BaseFeeCollectorInterface contains all external function interfaces
 *          for the fee collector implementation.
 */
interface BaseFeeCollectorInterface {
    /**
     * @notice Withdrawals the given amount of ERC20 tokens from the provided
     *         contract address
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param tokenContract    The ERC20 token address to be withdrawn.
     * @param amount           The amount of ERC20 tokens to be withdrawn.
     */
    function withdrawERC20Tokens(
        address withdrawalWallet,
        address tokenContract,
        uint256 amount
    ) external;

    /**
     * @notice Withdrawals the given amount of the native token from this
     *         contract to the withdrawal address. Requires the caller to
     *         have the operator role, and the withdrawal wallet to be in
     *         the allowlisted wallets.
     *
     * @param withdrawalWallet The wallet to be used for withdrawal.
     * @param amount           The amount of the native token to be withdrawn.
     */
    function withdraw(address withdrawalWallet, uint256 amount) external;

    /**
     * @notice Adds a new withdrawal address to the mapping. Requires
     *         the caller to be the owner and the withdrawal
     *         wallet to not be the null address.
     *
     * @param newWithdrawalWallet  The new withdrawal address.
     */
    function addWithdrawAddress(address newWithdrawalWallet) external;

    /**
     * @notice Removes the withdrawal address from the mapping. Requires
     *         the caller to be the owner.
     *
     * @param withdrawalWallet  The withdrawal address to
     *                             remove.
     */
    function removeWithdrawAddress(address withdrawalWallet) external;

    /**
     * @notice Assign the given address with the ability to operate the wallet.
     *
     * @param operatorToAssign The address to assign the operator role.
     */
    function assignOperator(address operatorToAssign) external;

    /**
     * @notice An external view function that returns a boolean.
     *
     * @return A boolean that determines if the provided address is
     *         a valid withdrawal wallet.
     */
    function isWithdrawalWallet(address withdrawalWallet)
        external
        view
        returns (bool);
}