// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function cbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = 0;
        for (uint256 y = 1 << 255; y > 0; y >>= 3) {
            x <<= 1;
            uint256 z = 3 * x * (x + 1) + 1;
            if (n / y >= z) {
                n -= y * z;
                x += 1;
            }
        }
        return x;
    }}
}

contract roots {

    uint immutable decimals0;
    uint immutable decimals1;
    bool immutable stable;
    address immutable token0;
    address immutable token1;

    constructor(uint _dec0, uint _dec1, bool _stable, address _t0, address _t1) {
        decimals0 = _dec0;
        decimals1 = _dec1;
        stable = _stable;
        token0 = _t0;
        token1 = _t1;
    }

    function _f(uint x0, uint xy, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18-xy;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
          uint y_prev = y;
          y = y - (_f(x0,xy,y)*1e18/_d(x0,y));
          if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
          } else {
                if (y_prev - y <= 1) {
                    return y;
                }
          }
        }
        return y;
    }

    function getAmountOutNewton(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1) external view returns (uint) {
    //   amountIn -= amountIn / 10000; // remove fee from amount received
      if (stable) {
          uint xy =  _k(_reserve0, _reserve1);
          _reserve0 = _reserve0 * 1e18 / decimals0;
          _reserve1 = _reserve1 * 1e18 / decimals1;
          (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
          amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
          uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
          return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
      } else {
          (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
          return amountIn * reserveB / (reserveA + amountIn);
      }
    }

    function _k(uint x, uint y) internal view returns (uint) {
      if (stable) {
          uint _x = x * 1e18 / decimals0;
          uint _y = y * 1e18 / decimals1;
          uint _a = (_x * _y) / 1e18;
          uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
          return _a * _b / 1e18;  // x3y+y3x >= k
      } else {
          return x * y; // xy >= k
      }
    }function _x4(uint x) internal pure returns (uint) {
        return x*x/1e18*x/1e18*x/1e18;
    }

    function _x3(uint x) internal pure returns (uint) {
        return x*x/1e18*x/1e18;
    }

    function _x9(uint x) internal pure returns (uint) {
        return _x4(x)*x/1e18*x/1e18*x/1e18*x/1e18*x/1e18;
    }

    function _x12(uint x) internal pure returns (uint) {
        return _x9(x)*x/1e18*x/1e18*x/1e18;
    }

    function _c0(uint a, uint b, uint x) internal pure returns (uint) {
        uint b3 = b*b/1e18*b/1e18;
        uint a3 = a*a/1e18*a/1e18;
        uint x2 = x*x/1e18;
        return 27*a3*b/1e18*x2/1e18+27*a*b3/1e18*x2/1e18;
    }

    function _c1(uint x, uint c0) internal pure returns (uint) {
        uint x12 = _x12(x);
        return (Math.sqrt(c0*c0+108e18*x12)+c0);
    }

    // Math.cbrt(2e54) = 1259921049894873164
    function _get_y2(uint xIn, uint a, uint b) internal pure returns (uint amountOut) {
        uint x = xIn+a;
        uint c1 = 0;
        uint b1 = 0;
        uint b2 = 0;
        {
            uint c0 = _c0(a, b, x);
            c1 = _c1(x, c0);
            c1 = Math.cbrt(c1*1e36)*1e18;
            b1 = 3e18*Math.cbrt(2e54)/1e18*x/1e18;
            b2 = (Math.cbrt(2e54)*_x3(x))*1e18;
        }

        uint y0 = c1/b1-b2/c1;
        return (b - y0);
    }

    function getAmountOutClosedForm(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1) external view returns (uint) {
    //   amountIn -= amountIn / 10000; // remove fee from amount received
      if (stable) {
          _reserve0 = _reserve0 * 1e18 / decimals0;
          _reserve1 = _reserve1 * 1e18 / decimals1;
          (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
          amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
          uint y = _get_y2(amountIn, reserveA, reserveB);
          return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
      } else {
          (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
          return amountIn * reserveB / (reserveA + amountIn);
      }
    }
}