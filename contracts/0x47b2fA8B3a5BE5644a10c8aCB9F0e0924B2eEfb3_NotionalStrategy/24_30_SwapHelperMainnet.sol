// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./SwapHelper.sol";

/// @title Swap helper implementation with SwapRouter02 on Mainnet
contract SwapHelperMainnet is SwapHelper {
    constructor()
        SwapHelper(ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    {}
}