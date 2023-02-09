// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../interfaces/SwapModule.sol";
import "../interfaces/IWETH9.sol";
import "../lib/BytesAddressLib.sol";

pragma solidity ^0.8.7;
pragma abicoder v2;

contract UniswapV3Module is SwapModule {
    using BytesAddressLib for bytes;
    using SafeERC20 for IERC20;

    error FailedRefund();
    error InvalidNativeSwap();

    address public immutable weth;
    address public immutable swapTarget;

    constructor(address _swapTarget, address _weth) {
        swapTarget = _swapTarget;
        weth = _weth;
    }

    /**
     * Decode the swap data that will be passed to the swap router
     * @param swapData the bytes swap data to be decoded
     * @return inputTokenAddress the address of the input token to be swapped
     * @return outputTokenAddress the address of the output token
     */
    function decodeSwapData(
        bytes calldata swapData
    ) external pure override returns (address inputTokenAddress, address outputTokenAddress) {
        return _decodeSwapData(swapData);
    }

    /**
     * @notice performs an exact output swap using native ETH and refunds the leftover ETH to the user
     * @param swapParams the parameters required to make the swap (See: SwapModule.ExactOutputParams)
     * @return inputTokenAmountSpent the amount of the input token spent to facilitate the swap
     */
    function exactOutputNativeSwap(ExactOutputParams calldata swapParams) external payable override returns (uint256) {
        IWETH9(weth).deposit{ value: swapParams.inputTokenAmountMax }();

        (address inputTokenAddress, uint256 inputTokenAmountSpent, uint256 remainingBalance) = _exactOutputSwap(
            swapParams
        );

        if (inputTokenAddress != weth) revert InvalidNativeSwap();

        // refund leftover tokens to original caller if there are any
        if (remainingBalance > 0) {
            IWETH9(weth).withdraw(remainingBalance);
            (bool success, ) = swapParams.from.call{ value: remainingBalance }("");
            if (!success) revert FailedRefund();
        }

        return inputTokenAmountSpent;
    }

    /**
     * @notice performs an exact output swap using an ERC-20 token and refunds leftover tokens to the user
     * @param swapParams the parameters required to make the swap (See: SwapModule.ExactOutputParams)
     * @return inputTokenAmountSpent the amount of the input token spent to facilitate the swap
     */
    function exactOutputSwap(ExactOutputParams calldata swapParams) public override returns (uint256) {
        (address inputTokenAddress, uint256 inputTokenAmountSpent, uint256 remainingBalance) = _exactOutputSwap(
            swapParams
        );

        // refund leftover tokens to original caller if there are any
        if (remainingBalance > 0 && swapParams.from != address(this)) {
            IERC20(inputTokenAddress).safeTransfer(swapParams.from, remainingBalance);
        }

        return inputTokenAmountSpent;
    }

    /**
     * @notice private method to perform an exact output swap on the v3 router
     * @param swapParams the parameters required to make the swap (See: SwapModule.ExactOutputParams)
     * @return inputTokenAddress the address of the token being swapped
     * @return inputTokenAmountSpent the amount of the input token spent to facilitate the swap
     * @return remainingBalance the leftover balance of the input token after the swap
     */
    function _exactOutputSwap(
        ExactOutputParams calldata swapParams
    ) private returns (address inputTokenAddress, uint256 inputTokenAmountSpent, uint256 remainingBalance) {
        (inputTokenAddress, ) = _decodeSwapData(swapParams.swapData);

        IERC20 inputToken = IERC20(inputTokenAddress);
        uint256 allowance = inputToken.allowance(address(this), swapTarget);

        if (allowance == 0) {
            inputToken.safeApprove(swapTarget, type(uint256).max);
        } else if (allowance < swapParams.inputTokenAmountMax) {
            inputToken.safeApprove(swapTarget, 0);
            inputToken.safeApprove(swapTarget, type(uint256).max);
        }

        (inputTokenAmountSpent, remainingBalance) = _swap(swapParams);
    }

    /**
     * @notice internal method to handle the underlying swap with the v3 router
     * @param swapParams the parameters required to make the swap (See: SwapModule.ExactOutputParams)
     * @return inputTokenAmountSpent the amount of the input token spent to facilitate the swap
     * @return remainingBalance the leftover balance of the input token after the swap
     */
    function _swap(
        ExactOutputParams calldata swapParams
    ) private returns (uint256 inputTokenAmountSpent, uint256 remainingBalance) {
        ISwapRouter router = ISwapRouter(swapTarget);

        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: swapParams.swapData,
            recipient: swapParams.to,
            deadline: swapParams.deadline,
            amountOut: swapParams.paymentTokenAmount,
            amountInMaximum: swapParams.inputTokenAmountMax
        });

        inputTokenAmountSpent = router.exactOutput(params);
        remainingBalance = swapParams.inputTokenAmountMax - inputTokenAmountSpent;
    }

    /**
     * @notice decode the input token and output token from the v3 swapData
     * @param swapData the uniswap v3 path
     * @dev v3 path is the encoded swap path and pool fees in *reverse* order (output token -> input token)
     * @return inputTokenAddress the address of the token being swapped
     * @return outputTokenAddress the address of the token being swapped to
     */
    function _decodeSwapData(
        bytes calldata swapData
    ) private pure returns (address inputTokenAddress, address outputTokenAddress) {
        inputTokenAddress = swapData.parseLastAddress();
        outputTokenAddress = swapData.parseFirstAddress();
    }

    receive() external payable {}
}