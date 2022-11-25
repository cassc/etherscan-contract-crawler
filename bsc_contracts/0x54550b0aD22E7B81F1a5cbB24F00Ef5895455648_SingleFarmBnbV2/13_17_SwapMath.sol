pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library  SwapMath {
    using SafeMath for uint256;
    // following: https://blog.alphafinance.io/onesideduniswap/
    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
    internal
    pure
    returns (uint256)
    {
        return
        sqrt(
            reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
        )
        .sub(reserveIn.mul(1997)) / 1994;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}