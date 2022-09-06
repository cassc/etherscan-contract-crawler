// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    INameIdentifier,
    IERC20
} from "contracts/common/Imports.sol";

/**
 * @notice Used to define a token swap that can be performed by an LP Account
 */
interface ISwap is INameIdentifier {
    /**
     * @dev Implementation should perform a token swap
     * @param amount The amount of the input token to swap
     * @param minAmount The minimum amount of the output token to accept
     */
    function swap(uint256 amount, uint256 minAmount) external;

    /**
     * @notice ERC20 asset allocations to include in TVL
     * @dev Should return addresses for all tokens going in and out of the swap
     * @return The array of ERC20 token addresses
     */
    function erc20Allocations() external view returns (IERC20[] memory);
}