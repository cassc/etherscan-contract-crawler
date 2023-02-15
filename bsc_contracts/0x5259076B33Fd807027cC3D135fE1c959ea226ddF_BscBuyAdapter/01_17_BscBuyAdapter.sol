// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "../../lib/uniswapv2/NewUniswapV2.sol";
import "../../lib/augustus-rfq/AugustusRFQ.sol";
import "../../lib/hashflow/HashFlow.sol";
import "../IBuyAdapter.sol";

/**
 * @dev This contract will route call to:
 * 1 - UniswapV2Forks
 * 2 - AugustusRFQ
 * 3 - HashFlow
 * The above are the indexes
 */
contract BscBuyAdapter is IBuyAdapter, NewUniswapV2, AugustusRFQ, HashFlow {
    using SafeMath for uint256;

    constructor(address _weth) public WethProvider(_weth) {}

    function initialize(bytes calldata data) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function buy(
        uint256 index,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxFromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) external payable override {
        if (index == 1) {
            buyOnUniswapFork(fromToken, toToken, maxFromAmount, toAmount, payload);
        } else if (index == 2) {
            buyOnAugustusRFQ(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else if (index == 3) {
            buyOnHashFlow(fromToken, toToken, maxFromAmount, toAmount, targetExchange, payload);
        } else {
            revert("Index not supported");
        }
    }
}