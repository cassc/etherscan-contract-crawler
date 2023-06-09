// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title KeyPairSwap
 */
contract SwapStructs {
    struct _1inchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    struct _0xSwapDescription {
        address inputToken;
        address outputToken;
        uint256 inputTokenAmount;
    }
} // end of class