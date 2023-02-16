// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../owner/Operator.sol";
import "../interfaces/IUniswapV2Factory.sol";

contract HasFactory is Operator {
    IUniswapV2Factory public FACTORY = IUniswapV2Factory(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10);

    // set pol address
    function setFactory(address factory) external onlyOperator {
        FACTORY = IUniswapV2Factory(factory);
    }
}