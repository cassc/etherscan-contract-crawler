// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    INameIdentifier,
    IERC20
} from "contracts/common/Imports.sol";

/**
 * @notice Used to define how an LP Account farms an external protocol
 */
interface IZap is INameIdentifier {
    /**
     * @notice Deploy liquidity to a protocol (i.e. enter a farm)
     * @dev Implementation should add liquidity and stake LP tokens
     * @param amounts Amount of each token to deploy
     */
    function deployLiquidity(uint256[] calldata amounts) external;

    /**
     * @notice Unwind liquidity from a protocol (i.e exit a farm)
     * @dev Implementation should unstake LP tokens and remove liquidity
     * @dev If there is only one token to unwind, `index` should be 0
     * @param amount Amount of liquidity to unwind
     * @param index Which token should be unwound
     */
    function unwindLiquidity(uint256 amount, uint8 index) external;

    /**
     * @notice Claim accrued rewards from the protocol (i.e. harvest yield)
     */
    function claim() external;

    /**
     * @notice Retrieves the LP token balance
     */
    function getLpTokenBalance(address account) external view returns (uint256);

    /**
     * @notice Order of tokens for deploy `amounts` and unwind `index`
     * @dev Implementation should use human readable symbols
     * @dev Order should be the same for deploy and unwind
     * @return The array of symbols in order
     */
    function sortedSymbols() external view returns (string[] memory);

    /**
     * @notice Asset allocations to include in TVL
     * @dev Requires all allocations that track value deployed to the protocol
     * @return An array of the asset allocation names
     */
    function assetAllocations() external view returns (string[] memory);

    /**
     * @notice ERC20 asset allocations to include in TVL
     * @dev Should return addresses for all tokens that get deployed or unwound
     * @return The array of ERC20 token addresses
     */
    function erc20Allocations() external view returns (IERC20[] memory);
}