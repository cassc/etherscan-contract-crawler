// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./features/ContractOnlyEthRecipient.sol";
import "./features/TokenExtension.sol";
import "./features/UniswapV3Executor.sol";
import "./Constants.sol";
import "@1inch/solidity-utils/contracts/libraries/RevertReasonParser.sol";
import "./interfaces/ISwapExecutor.sol";
import "./libs/SafeERC20Ext.sol";
import "./libs/TokenLibrary.sol";
import "./libs/LowLevelHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SwapExecutor
 * @notice Contract that performs actual swaps. It iterate over calldatas being passed and executes them. This means that users of this contract
 * shall be exeptionally careful about how they do call it, which is why we don't recomment to use it directly except for complex scenarios where
 * this contract might be part of a bigger flow designed by actual solidity developers that will make all sanity checks on their side.
 * SwapFacade is an example of implementation that provide necessary failsafe checks for actual users.
 * This contract also manages fees that might occur during swaps. Callers might check fee values and revert if they are disagree on it
 */
contract SwapExecutor is
    Ownable,
    UniswapV3Executor,
    ContractOnlyEthRecipient,
    TokenExtension,
    ISwapExecutor
{
    using TokenLibrary for IERC20;
    using SafeERC20 for IERC20;
    using SafeERC20Ext for IERC20;

    uint256 public feeAndFeeRecipient;

    event FeeAndFeeRecipientChanged(uint256 oldValue, uint256 newValue);

    /// @notice Creates an executor
    /// @param wethArg address of WETH token
    /// @param feeAndFeeRecipient_ lowest 160 bytes are address, the rest is 1E18 based fee amount
    // solhint-disable-next-line no-empty-blocks
    constructor(IWETH wethArg, uint256 feeAndFeeRecipient_) TokenExtension(wethArg) {
        feeAndFeeRecipient = feeAndFeeRecipient_;
    }

    /// @notice Allows to update fee and fee recipient
    /// @param feeAndFeeRecipient_ lowest 160 bytes are address, the rest is 1E18 based fee amount
    function setFeeAndFeeRecipient(uint256 feeAndFeeRecipient_) external onlyOwner {
        uint256 oldValue = feeAndFeeRecipient;
        feeAndFeeRecipient = feeAndFeeRecipient_;
        emit FeeAndFeeRecipientChanged(oldValue, feeAndFeeRecipient_);
    }

    /// @notice Performs tokens swap
    /// @param recipient recipient that should receive tokens
    /// @param tokenToTransfer address of last token in chain token that should be transferred to recipient
    /// @param swapDescriptions descriptions that describe how exactly swaps should be performed
    function executeSwap(address payable recipient, IERC20 tokenToTransfer, SwapDescription[] calldata swapDescriptions) external payable {
        unchecked {
            for (uint256 i = 0; i < swapDescriptions.length; i++) {
                IERC20 sourceToken = swapDescriptions[i]
                    .sourceToken;
                uint256 balanceToSwap = sourceToken
                    .universalBalanceOf(address(this));
                if (balanceToSwap == 0) {
                    revert SwapTotalAmountCannotBeZero();
                }
                // keeping 1 wei on contract for cheaper swaps
                balanceToSwap--;
                TargetSwapDescription[] calldata swaps = swapDescriptions[i].swaps;
                for (uint256 j = 0; j < swaps.length; j++) {
                    TargetSwapDescription calldata swap = swaps[j];
                    uint256 poolSwapAmount = (balanceToSwap * swap.tokenRatio) / _ONE;
                    if (poolSwapAmount == 0) {
                        revert SwapAmountCannotBeZero();
                    }
                    // May be useful if say we want to transfer some funds to recipient without executing a swaps
                    if (swap.data.length > 0) {
                        // solhint-disable avoid-low-level-calls
                        bool success;
                        bytes memory result;
                        if (swap.callType == CallType.Direct) {
                            uint256 value = performSourceTokenInteractionAndGetEthValue(sourceToken, swap.sourceInteraction, poolSwapAmount, swap.target);
                            bytes memory data = swap.amountOffset != type(uint256).max // flag meaning no patching is required
                             ? LowLevelHelper.patchUint(swap.data, poolSwapAmount, swap.amountOffset)
                             : swap.data;
                            (success, result) = swap.target.call{ value: value }(data);
                        }
                        else if (swap.callType == CallType.Calculated) {
                            (success, result) = swap.target.call(
                                LowLevelHelper.patchUint(swap.data, poolSwapAmount, swap.amountOffset)
                            );
                            if (!success) {
                                string memory reason = RevertReasonParser.parse(
                                    result,
                                    "SEHEC: "
                                );
                                revert(reason);
                            }
                            (address target, bytes memory data) = abi.decode(result, (address, bytes));
                            uint256 value = performSourceTokenInteractionAndGetEthValue(sourceToken, swap.sourceInteraction, poolSwapAmount, target);
                            (success, result) = target.call{ value: value }(data);
                        }
                        else {
                            revert EnumOutOfRangeValue(EnumType.CallType, uint256(swap.callType));
                        }
                        if (!success) {
                            string memory reason = RevertReasonParser.parse(
                                result,
                                "SEEC: "
                            );
                            revert(reason);
                        }
                    }
                }
            }

            address payable feeRecipient = payable(address(uint160(feeAndFeeRecipient)));
            uint256 decodedFee = feeAndFeeRecipient >> 160;
            uint256 fee = decodedFee > 0 && feeRecipient != address(0) ? decodedFee : 0;
            uint256 balanceOfThis = tokenToTransfer.universalBalanceOf(address(this));
            if (balanceOfThis <= 1) {
                revert EmptySwapOnExecutor();
            }
            balanceOfThis--;
            uint256 feeAmount = balanceOfThis * fee / _ONE;
            uint256 amount = balanceOfThis - feeAmount;
            tokenToTransfer.universalTransfer(feeRecipient, feeAmount);
            tokenToTransfer.universalTransfer(recipient, amount);
        }
    }

    /// @notice Performs source token interaction required by protocol, such as approve, transfer or anything else.
    /// @return Result Amount of ether that should be provided to call `target`
    function performSourceTokenInteractionAndGetEthValue(IERC20 sourceToken, SourceTokenInteraction sourceInteraction, uint256 poolSwapAmount, address target) private returns (uint256) {
        if (sourceToken.isEth()) {
            return poolSwapAmount;
        }
        // solhint-disable-next-line no-empty-blocks
        if (sourceInteraction == SourceTokenInteraction.None) {
        }
        else if (sourceInteraction == SourceTokenInteraction.ApproveToTarget) {
            sourceToken.setAllowance(target, poolSwapAmount);
        }
        else if (sourceInteraction == SourceTokenInteraction.TransferToTarget) {
            sourceToken.safeTransfer(target, poolSwapAmount);
        }
        else {
            revert EnumOutOfRangeValue(EnumType.SourceTokenInteraction, uint256(sourceInteraction));
        }
        return 0;
    }
}