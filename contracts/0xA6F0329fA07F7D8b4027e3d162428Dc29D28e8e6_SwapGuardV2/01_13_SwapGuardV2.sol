// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./features/ContractOnlyEthRecipient.sol";
import "./libs/TokenLibrary.sol";

/**
 * @title SwapGuard
 * @notice This contract is used to limit the amount of tokens that can be lost in a single transaction
 */
contract SwapGuardV2 {
    using SafeCast for uint256;
    using SafeCast for int256;
    using TokenLibrary for IERC20;

    error LostMoreThanAllowed(uint256, uint256);
    error InvalidGuardUsage();
    mapping(address => uint256) private checkpoint;

    address private msgSender;

    /// @notice creates a checkpoint of the balances of tokens
    function makeCheckpoint(address vault, IERC20[] calldata tokens) external {
        // Do not revert if msgSender already set otherwise it's trivial to invoke DoS of this contract
        msgSender = msg.sender;
        unchecked {
            for (uint256 i = 0; i < tokens.length; i++) {
                // checkpoint[address(tokens[i])] = tokens[i].balanceOf(vault);
                checkpoint[address(tokens[i])] = tokens[i].universalBalanceOf(vault);
            }
        }
    }

    /// @notice ensures that the balances of tokens didn't change more than allowed
    /// @param vault Address of the vault
    /// @param tokens Array of tokens to check
    /// @param tokenPrices Array of prices of tokens
    /// @param balanceChanges Array of expected balance changes
    /// @param allowedLoss Maximum amount of tokens that can be lost
    function ensureCheckpoint(
        address vault,
        IERC20[] calldata tokens,
        uint256[] calldata tokenPrices,
        int256[] calldata balanceChanges,
        uint256 allowedLoss
    ) external {
        if (msgSender != msg.sender) {
            revert InvalidGuardUsage();
        }
        msgSender = address(0);
        unchecked {
            uint256 totalLoss = 0;
            // check that we didn't loose more than allowedLoss
            // it is okay if we got more than expected
            for (uint256 i = 0; i < tokens.length; i++) {
                IERC20 token = tokens[i];
                uint256 balancesBeforeInteraction = checkpoint[address(token)];
                uint256 balanceAfterInteraction = tokens[i].universalBalanceOf(vault);
                int256 expectedBalanceChange = balanceChanges[i];
                int256 actualBalanceChange = balanceAfterInteraction.toInt256() - balancesBeforeInteraction.toInt256();
                if (actualBalanceChange < expectedBalanceChange) {
                    totalLoss += (expectedBalanceChange - actualBalanceChange).toUint256() * tokenPrices[i];
                }
                if (totalLoss > allowedLoss) {
                    revert LostMoreThanAllowed(totalLoss, allowedLoss);
                }
                checkpoint[address(token)] = 0; // gas refund
            }
        }
    }
}