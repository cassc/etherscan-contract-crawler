// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IFeeDistributor } from "./IFeeDistributor.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A smart contract for buying any kind of tokens and taking a fee.
interface ITokenBuyer is IFeeDistributor {
    /// @notice A token address-amount pair.
    struct PayToken {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Executes token swaps and takes a fee.
    /// @param guildId The id of the guild where the payment was made. Used only for analytics.
    /// @param payToken The address and the amount of the token that's used for paying. 0 for ether.
    /// @param uniCommands A set of concatenated commands, each 1 byte in length.
    /// @param uniInputs An array of byte strings containing abi encoded inputs for each command.
    function getAssets(
        uint256 guildId,
        PayToken calldata payToken,
        bytes calldata uniCommands,
        bytes[] calldata uniInputs
    ) external payable;

    /// @notice Allows the feeCollector to withdraw any tokens stuck in the contract. Used to rescue funds.
    /// @param token The address of the token to sweep. 0 for ether.
    /// @param recipient The recipient of the tokens.
    /// @param amount The amount of the tokens to sweep.
    function sweep(address token, address payable recipient, uint256 amount) external;

    /// @notice Returns the address of Uniswap's Universal Router.
    function universalRouter() external view returns (address payable);

    /// @notice Returns the address the Permit2 contract.
    function permit2() external view returns (address);

    /// @notice Event emitted when a call to {getAssets} succeeds.
    /// @param guildId The id of the guild where the payment was made. Used only for analytics.
    event TokensBought(uint256 guildId);

    /// @notice Event emitted when tokens are sweeped from the contract.
    /// @dev Callable only by the current fee collector.
    /// @param token The address of the token sweeped. 0 for ether.
    /// @param recipient The recipient of the tokens.
    /// @param amount The amount of the tokens sweeped.
    event TokensSweeped(address token, address payable recipient, uint256 amount);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);
}