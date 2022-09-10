//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ZunamiDepositor.sol";
import '../../utils/ConstantsBSC.sol';

contract ZunamiDepositorBUSD is ZunamiDepositor {
    constructor(
        address _gateway
    ) public ZunamiDepositor(
        ConstantsBSC.BUSD_ADDRESS,
        ConstantsBSC.USDT_ADDRESS,
        _gateway,
        ConstantsBSC.PANCAKESWAP_ROUTER_ADDRESS
    ) { }
}