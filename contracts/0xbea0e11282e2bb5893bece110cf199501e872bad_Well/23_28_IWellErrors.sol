// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWellErrors defines all Well errors.
 * @dev The errors are separated into a different interface as not all Well
 * implementations may share the same errors.
 */
interface IWellErrors {
    /**
     * @notice Thrown when an operation would deliver fewer tokens than `minAmountOut`.
     */
    error SlippageOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @notice Thrown when an operation would require more tokens than `maxAmountIn`.
     */
    error SlippageIn(uint256 amountIn, uint256 maxAmountIn);

    /**
     * @notice Thrown if one or more tokens used in the operation are not supported by the Well.
     */
    error InvalidTokens();

    /**
     * @notice Thrown if this operation would cause an incorrect change in Well reserves.
     */
    error InvalidReserves();

    /**
     * @notice Thrown when a Well is bored with duplicate tokens.
     */
    error DuplicateTokens(IERC20 token);

    /**
     * @notice Thrown if an operation is executed after the provided `deadline` has passed.
     */
    error Expired();
}