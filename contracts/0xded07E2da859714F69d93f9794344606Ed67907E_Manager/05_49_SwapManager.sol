// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../interfaces/hub/IMuffinHub.sol";
import "../../interfaces/manager/ISwapManager.sol";
import "../../libraries/math/Math.sol";
import "./ManagerBase.sol";

abstract contract SwapManager is ISwapManager, ManagerBase {
    using Math for uint256;

    error DeadlinePassed();

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    /// @dev Reverts if the transaction deadline has passed
    function _checkDeadline(uint256 deadline) internal view {
        if (block.timestamp > deadline) revert DeadlinePassed();
    }

    /// @dev Called by the hub contract
    function muffinSwapCallback(
        address tokenIn,
        address, // tokenOut,
        uint256 amountIn,
        uint256, // amountOut,
        bytes calldata data
    ) external fromHub {
        if (amountIn > 0) payHub(tokenIn, abi.decode(data, (address)), amountIn);
    }

    /**
     * @notice                  Swap `amountIn` of one token for as much as possible of another token
     * @param tokenIn           Address of input token
     * @param tokenOut          Address of output token
     * @param tierChoices       Bitmap to select which tiers are allowed to swap (e.g. 0xFFFF to allow all possible tiers)
     * @param amountIn          Desired input amount
     * @param amountOutMinimum  Minimum output amount
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountOut        Output amount of the swap
     */
    function exactInSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 amountOut) {
        (, amountOut) = IMuffinHub(hub).swap(
            tokenIn,
            tokenOut,
            tierChoices,
            amountIn.toInt256(),
            toAccount ? address(this) : recipient,
            toAccount ? getAccRefId(recipient) : 0,
            fromAccount ? getAccRefId(msg.sender) : 0,
            abi.encode(msg.sender)
        );
        require(amountOut >= amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /**
     * @notice                  Swap `amountIn` of one token for as much as possible of another along the specified path
     * @param path              Multi-hop path
     * @param amountIn          Desired input amount
     * @param amountOutMinimum  Minimum output amount
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountOut        Output amount of the swap
     */
    function exactIn(
        bytes calldata path,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 amountOut) {
        (, amountOut) = IMuffinHub(hub).swapMultiHop(
            IMuffinHubActions.SwapMultiHopParams({
                path: path,
                amountDesired: amountIn.toInt256(),
                recipient: toAccount ? address(this) : recipient,
                recipientAccRefId: toAccount ? getAccRefId(recipient) : 0,
                senderAccRefId: fromAccount ? getAccRefId(msg.sender) : 0,
                data: abi.encode(msg.sender)
            })
        );
        require(amountOut >= amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

    /**
     * @notice                  Swap as little as possible of one token for `amountOut` of another token
     * @param tokenIn           Address of input token
     * @param tokenOut          Address of output token
     * @param tierChoices       Bitmap to select which tiers are allowed to swap (e.g. 0xFFFF to allow all possible tiers)
     * @param amountOut         Desired output amount
     * @param amountInMaximum   Maximum input amount to pay
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountIn         Input amount of the swap
     */
    function exactOutSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 amountIn) {
        (amountIn, ) = IMuffinHub(hub).swap(
            tokenIn,
            tokenOut,
            tierChoices,
            -amountOut.toInt256(),
            toAccount ? address(this) : recipient,
            toAccount ? getAccRefId(recipient) : 0,
            fromAccount ? getAccRefId(msg.sender) : 0,
            abi.encode(msg.sender)
        );
        require(amountIn <= amountInMaximum, "TOO_MUCH_REQUESTED");
    }

    /**
     * @notice                  Swap as little as possible of one token for `amountOut` of another along the specified path
     * @param path              Address of output token
     * @param amountOut         Desired output amount
     * @param amountInMaximum   Maximum input amount to pay
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountIn         Input amount of the swap
     */
    function exactOut(
        bytes calldata path,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 amountIn) {
        (amountIn, ) = IMuffinHub(hub).swapMultiHop(
            IMuffinHubActions.SwapMultiHopParams({
                path: path,
                amountDesired: -amountOut.toInt256(),
                recipient: toAccount ? address(this) : recipient,
                recipientAccRefId: toAccount ? getAccRefId(recipient) : 0,
                senderAccRefId: fromAccount ? getAccRefId(msg.sender) : 0,
                data: abi.encode(msg.sender)
            })
        );
        require(amountIn <= amountInMaximum, "TOO_MUCH_REQUESTED");
    }
}