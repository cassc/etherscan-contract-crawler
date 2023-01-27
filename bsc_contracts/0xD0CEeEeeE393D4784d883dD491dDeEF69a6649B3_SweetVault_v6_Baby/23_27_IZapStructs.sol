/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../interfaces/IPancakeRouter02.sol";

interface IZapStructs {
    struct InitialBalances {
        uint token0;
        uint token1;
        uint inputToken;
    }

    struct Pair {
        address token0;
        address token1;
    }

    struct ZapInfo {
        IPancakeRouter02 router;
        address[] pathToToken0;
        address[] pathToToken1;
        address outputToken;
        uint minToken0;
        uint minToken1;
    }

    struct UnZapInfo {
        IPancakeRouter02 router;
        address[] pathFromToken0;
        address[] pathFromToken1;
        address inputToken;
        uint inputTokenAmount;
        uint minOutputTokenAmount;
    }

    struct ZapPairInfo {
        IPancakeRouter02 routerSwap;
        IPancakeRouter02 routerIn;
        IPancakeRouter02 routerOut;
        address[] pathFromToken0; // (token0 of inputToken)
        address[] pathFromToken1; // (token1 of inputToken)
        address inputToken;
        address outputToken;
        uint inputTokenAmount;
        uint minTokenA;
        uint minTokenB;
    }
}