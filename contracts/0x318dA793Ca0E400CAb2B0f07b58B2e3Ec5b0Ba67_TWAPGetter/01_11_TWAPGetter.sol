//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

contract TWAPGetter {
    /**
     * @notice Check for zero address
     * @dev Modifier
     * @param _address the address to check
     */
    modifier checkZeroAddress(address _address) {
        require(_address != address(0), 'Address cannot be zero');
        _;
    }

    function getPrice(
        address _uniswapV3Pool,
        address _baseToken,
        address _quoteToken,
        uint32 _twapInterval
    ) public view returns (uint256 quoteAmount) {
        uint32 baseDecimals = IERC20Extended(_baseToken).decimals();
        uint256 baseAmount = 10 ** baseDecimals;

        uint160 sqrtPriceX96 = _getSqrtTwapX96(_uniswapV3Pool, _twapInterval);
        uint256 priceX192 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 shift = uint256(1 << 192);

        // qouteAmount should be divided by 10**qouteDecimals
        if (_baseToken < _quoteToken) {
            quoteAmount = FullMath.mulDiv(priceX192, baseAmount, shift);
        } else {
            quoteAmount = FullMath.mulDiv(shift, baseAmount, priceX192);
        }
    }

    function _getSqrtTwapX96(
        address _uniswapV3Pool,
        uint32 _twapInterval
    ) internal view returns (uint160 sqrtPriceX96) {
        if (_twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(_uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = _twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(_uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / _twapInterval)
            );
        }
    }
}