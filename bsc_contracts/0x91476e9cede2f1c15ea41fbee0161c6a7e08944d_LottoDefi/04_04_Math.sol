pragma solidity ^0.8.7;

//SPDX-License-Identifier: LGPL-3.0-or-later

contract LMath {
    

    function add(uint256 x, uint256 y) internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) internal returns (uint256 z) {
        return x >= y ? x : y;
    }



    function hadd(uint128 x, uint128 y) internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) internal returns (uint128 z) {
        return x >= y ? x : y;
    }



    function imin(int256 x, int256 y) internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) internal returns (int256 z) {
        return x >= y ? x : y;
    }


    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) internal returns (uint128) {
        return hmax(x, y);
    }


    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) internal returns (uint128 z) {

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}