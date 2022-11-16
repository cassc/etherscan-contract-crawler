// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import "../lib/Types.sol";

interface IExecutionNodeEvents {
    /**
     * @notice Emitted when operations on dst chain is done.
     * @param id see _computeId()
     * @param amountOut the amount of tokenOut from this step
     * @param tokenOut the token that is outputted from this step
     */
    event StepExecuted(bytes32 id, uint256 amountOut, address tokenOut);

    event PocketFundClaimed(address receiver, uint256 erc20Amount, address token, uint256 nativeAmount);
}