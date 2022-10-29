// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/Permitable.sol";
import "./features/ContractOnlyEthRecipient.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISwapExecutor.sol";
import "./libs/TokenLibrary.sol";
import "./Errors.sol";

/**
 * @title SwapFacade
 * @notice This facade performs minReturn safety checks and holds all approves to ensure safety of all arbitrary calls
 */
contract SwapFacade is ContractOnlyEthRecipient, Permitable {
    using SafeERC20 for IERC20;
    using TokenLibrary for IERC20;

    /// @notice Performs tokens swap
    /// @param executor Address of low level executor used to make actual swaps
    /// @param amount Amount of source tokens user is willing to swap
    /// @param targetToken Token that user is willing to get as result. This will be used for minReturn check to decide if swap executed successfully
    /// @param minReturn Minimal amount of targetToken that user is willing to receive. If not reached transaction reverts
    /// @param deadline Safety parameter against stalled transactions. If deadline reached swap reverts unconditionally
    /// @param swapDescriptions Descriptions that describe how exactly swaps should be performed
    /// @param permit Signed permit for spending `amount` of tokens. Optional. May be used instead of manually approving tokens before calling `swap`
    function swap(
        ISwapExecutor executor,
        uint256 amount,
        IERC20 targetToken,
        uint256 minReturn,
        address payable recipient,
        uint256 deadline,
        ISwapExecutor.SwapDescription[] calldata swapDescriptions,
        bytes calldata permit
    ) external payable returns (uint256) {
        {
            // solhint-disable-next-line not-rely-on-time
            if (deadline < block.timestamp) {
                // solhint-disable-next-line not-rely-on-time
                revert TransactionExpired(deadline, block.timestamp);
            }
        }
        if (swapDescriptions.length == 0) {
            revert EmptySwap();
        }
        IERC20 sourceToken = swapDescriptions[0].sourceToken;
        if (msg.value > 0) {
            if (msg.value != amount) {
                revert EthValueAmountMismatch();
            } else if (permit.length > 0) {
                revert PermitNotAllowedForEthSwap();
            } else if (!TokenLibrary.isEth(sourceToken)) {
                revert EthValueSourceTokenMismatch();
            }
        }
        else {
            uint256 currentBalance = sourceToken.balanceOf(address(executor));
            if (currentBalance < amount)
            {
                if (permit.length > 0) {
                    _permit(address(sourceToken), permit);
                }
                uint256 approveAmount = sourceToken.allowance(
                    msg.sender,
                    address(this)
                );
                if (approveAmount < amount) {
                    revert NotEnoughApprovedFundsForSwap(approveAmount, amount);
                }
                sourceToken.safeTransferFrom(msg.sender, address(executor), amount);
            }
        }
        return _swap(executor, targetToken, minReturn, recipient, swapDescriptions);
    }

    /// @notice Performs tokens swap and validates swap success against minReturn value
    function _swap(
        ISwapExecutor executor,
        IERC20 targetToken,
        uint256 minReturn,
        address payable recipient,
        ISwapExecutor.SwapDescription[] calldata swapDescriptions
    ) private returns (uint256) {
        uint256 balanceBeforeSwap = targetToken.universalBalanceOf(recipient);
        executor.executeSwap{value: msg.value}(recipient, targetToken, swapDescriptions);
        uint256 balanceAfterSwap = targetToken.universalBalanceOf(recipient);
        uint256 totalSwappedAmount = balanceAfterSwap - balanceBeforeSwap;
        if (totalSwappedAmount < minReturn) {
            revert MinReturnError(totalSwappedAmount, minReturn);
        }
        return totalSwappedAmount;
    }
}