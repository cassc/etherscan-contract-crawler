// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IExpectedOutCalculator} from "./interfaces/IExpectedOutCalculator.sol";
import {IRocketPoolEth} from "./interfaces/IRocketPoolEth.sol";
import {IWstEth} from "./interfaces/IWstEth.sol";

contract WstethRethExpectedOutPriceChecker is IExpectedOutCalculator {
    address public constant ROCKET_POOL_ETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant LIDO_WST_ETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    error INVALID_TOKEN_PAIR();

    function getExpectedOut(uint256 _amountIn, address _fromToken, address _toToken, bytes calldata)
        external
        view
        override
        returns (uint256)
    {
        if (_fromToken == LIDO_WST_ETH && _toToken == ROCKET_POOL_ETH) {
            uint256 amountStEth = IWstEth(LIDO_WST_ETH).getStETHByWstETH(_amountIn);
            return IRocketPoolEth(ROCKET_POOL_ETH).getRethValue(amountStEth);
        }
        if (_fromToken == ROCKET_POOL_ETH && _toToken == LIDO_WST_ETH) {
            uint256 amountEth = IRocketPoolEth(ROCKET_POOL_ETH).getEthValue(_amountIn);
            return IWstEth(LIDO_WST_ETH).getWstETHByStETH(amountEth);
        }
        revert INVALID_TOKEN_PAIR();
    }
}