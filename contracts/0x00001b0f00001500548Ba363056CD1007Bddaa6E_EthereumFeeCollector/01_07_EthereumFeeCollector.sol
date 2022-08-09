// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { BaseFeeCollector } from "./base/BaseFeeCollector.sol";

import {
    EthereumFeeCollectorInterface,
    WETHInterface
} from "./interfaces/EthereumFeeCollectorInterface.sol";

/**
 * @title   EthereumFeeCollector
 * @author  OpenSea Protocol Team
 * @notice  EthereumFeeCollector is a contract that is used as an
 *          implementation for a beacon proxy. It inherits the
 *          BaseFeeCollector allowing for native token and ERC20
 *          token withdrawals. In addition, allowing for unwrapping
 *          and transferring WETH.
 */
contract EthereumFeeCollector is
    BaseFeeCollector,
    EthereumFeeCollectorInterface
{
    constructor() BaseFeeCollector() {}

    /**
     * @notice Unwraps and withdraws the given amount of WETH tokens from the
     *         provided contract address. Requires the caller to have the
     *         operator role, and the withdrawal wallet to be in the
     *         allowlisted wallets.
     *
     * @param withdrawalWallet      The wallet to be used for withdrawal.
     * @param wrappedTokenContract  The token address to be unwrapped.
     * @param amount                The amount of tokens to be withdrawn.
     */
    function unwrapAndWithdraw(
        address withdrawalWallet,
        address wrappedTokenContract,
        uint256 amount
    ) external override isOperator {
        // Ensure the withdrawal wallet is in the withdrawal wallet mapping.
        if (_withdrawalWallets[withdrawalWallet] != true) {
            revert InvalidWithdrawalWallet(withdrawalWallet);
        }

        // Make the withdraw call on the provided wrapped token.
        (bool result, bytes memory data) = wrappedTokenContract.call(
            abi.encodeWithSelector(WETHInterface.withdraw.selector, amount)
        );

        // Revert if we have a false result.
        if (!result) {
            revert TokenTransferGenericFailure(
                wrappedTokenContract,
                withdrawalWallet,
                0,
                amount
            );
        }

        // Revert if we have a bad return value.
        if (data.length != 0 && data.length >= 32) {
            if (!abi.decode(data, (bool))) {
                revert BadReturnValueFromERC20OnTransfer(
                    wrappedTokenContract,
                    withdrawalWallet,
                    amount
                );
            }
        }

        // Transfer the now unwrapped tokens to the withdrawal address.
        payable(withdrawalWallet).transfer(amount);
    }

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function name() external pure override returns (string memory) {
        // Return the name of the contract.
        return "ethereum-fee-collector";
    }
}