// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./BaseERC20.sol";

contract PepeGpt is BaseERC20 {
    constructor()
        BaseERC20(
            0x3404F2E9924503D259A04783b7fEC7E33B216b78,
            "pepeGPT",
            "pepeGPT",
            420690000000000 ether
        )
    {}
}