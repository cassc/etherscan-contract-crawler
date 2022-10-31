// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IAggregationExecutor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAggregationRouterV4 {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /**
     * @dev Function for swap tokens
     * @param caller Executor or caller address
     * @param desc Swap description
     * @param data swap route data
     * @return returnAmount Amount of destination token after swap
     * @return gasLeft Amount of gasLeft
     *
     */

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 gasLeft);

    /**
     * @dev Function is called when uniswap exchange for token swap
     * @param srcToken source token
     * @param amount Amount of source tokens to swap
     * @param minReturn Minimal allowed returnAmount to make transaction commit
     * @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
     * @return returnAmount Amount of tokens after swap
     */

    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns (uint256 returnAmount);

    /**
     * @dev Function is called when uniswapV3 exchange for token swap
     * @param amount Amount of source tokens to swap
     * @param minReturn Minimal allowed returnAmount to make transaction commit
     * @param pools Pools chain used for swaps. Pools src and dst tokens should match to make swap happen
     * @return returnAmount Amount of tokens after swap
     */

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    /**
     * @dev Function is called when clipper exchange for token swap
     * @param srcToken Source token
     * @param dstToken Destination token
     * @param amount Amount of source tokens to swap
     * @param minReturn Minimal allowed returnAmount to make transaction commit
     * @return returnAmount Amount of tokens after swap
     */

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount);
}