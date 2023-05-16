// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/SafeToken.sol";
import "../interface/IPair.sol";

contract SimpliRoute {

    using SafeToken for address;

    /// @notice SimpliRoute
    /// given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut,
        uint feeE4
    ) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * feeE4;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @dev Compute optimal deposit amount
    /// @param amtA amount of token A desired to deposit
    /// @param amtB amonut of token B desired to deposit
    /// @param resA amount of token A in reserve
    /// @param resB amount of token B in reserve
    function optimalDeposit(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB,
        uint256 feeE4
    ) internal pure returns (uint256 swapAmt, bool isReversed) {
        if (amtA * resB == amtB * resA) {
            swapAmt = 0;
            isReversed = false;
        }
        // else fix gas
        else if (amtA * resB > amtB * resA) {
            swapAmt = _optimalDepositA(amtA, amtB, resA, resB, feeE4);
            isReversed = false;
        }
        else {
            swapAmt = _optimalDepositA(amtB, amtA, resB, resA, feeE4);
            isReversed = true;
        }
    }

    function _optimalDepositA(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB,
        uint256 feeE4
    ) internal pure returns (uint256) {
        require(amtA * resB >= amtB * resA, "Reversed");
        uint256 a = feeE4;
        uint256 b = (1e4 + feeE4) * resA;
        uint256 _c = amtA * resB - amtB * resA;
        uint256 c = _c * 1e4  * resA / (amtB + resB);

        uint256 d = 4 * a * c;
        uint256 e = sqrt(b ** 2 + d);
        uint256 numerator = e - b;
        uint256 denominator = 2*a;
        return numerator / denominator;
    }

    /// @notice get price
    function _price(
        address _tokenIn,
        address _tokenOut,
        address _lpAddress,
        uint _amountIn,
        uint _feeE4
    ) internal view returns(uint _buyAmount){
        IPair _lp = IPair(_lpAddress);
        (uint112 reserveIn, uint112 reserveOut,) = _lp.getReserves();
        /// defult _tokenOut = _token1
        if ( _tokenIn > _tokenOut ) (reserveIn, reserveOut) = (reserveOut, reserveIn);
        _buyAmount = getAmountOut(_amountIn, reserveIn, reserveOut, _feeE4);
    }

    /// @notice get need token amount
    function _getAmountsForLiquidity(
        address _token0,
        address _token1,
        address _lpAddress,
        uint _liquidity
    ) internal view returns(uint _amount0, uint _amount1){
        IPair _lp = IPair(_lpAddress);
        (uint112 reserve0, uint112 reserve1,) = _lp.getReserves();
        /// 默认 _tokenOut = _token1
        if ( _token0 > _token1 ) (reserve0, reserve1) = (reserve1, reserve0);
        uint _totalSupply = _lp.totalSupply();
        _amount0 = _liquidity * reserve0 / _totalSupply;
        _amount1 = _liquidity * reserve1 / _totalSupply;  
    }

    /// @notice swap
    function _sawp(
        address _tokenIn,
        address _tokenOut,
        address _lpAddress,
        uint _amountIn,
        uint _feeE4, // 9975 = 99.75 % => 0.25% fee
        uint _slipE4, // 9000 = 90 % => 10% slippage
        address _to
    ) internal returns(uint _buyAmount){
        IPair _lp = IPair(_lpAddress);
        (uint112 reserveIn, uint112 reserveOut,) = _lp.getReserves();
        /// _tokenOut = _token1
        if ( _tokenIn > _tokenOut ) (reserveIn, reserveOut) = (reserveOut, reserveIn);


        _tokenIn.safeTransfer(_lpAddress, _amountIn);
        
        _amountIn = _tokenIn.balanceOf(_lpAddress) - reserveIn;

        uint _amount1 = getAmountOut(_amountIn, reserveIn, reserveOut, _feeE4);
        uint _amount0 = 0;
        
        if ( _tokenIn > _tokenOut ) (_amount0, _amount1) = (_amount1, _amount0);


        uint _before = _tokenOut.balanceOf(_to);
        _lp.swap(_amount0, _amount1, _to, new bytes(0));
        _buyAmount = _tokenOut.balanceOf(_to) - _before;
        require(_buyAmount >=  _slipE4 * _amount1 / 1e5, "buy error");
    }

    /// @notice buy for add liquidity
    function _addLpForBuy(
        address _tokenA,
        address _tokenB,
        address _lpAddress,
        uint _amountA,
        uint _amountB,
        uint _feeE4,
        address _to
    ) internal {
        IPair _lp = IPair(_lpAddress);
        (uint112 _resA, uint112 _resB,) = _lp.getReserves();
        if ( _tokenA > _tokenB ) (_resA, _resB) = (_resB, _resA);

        (uint _swapAmount, bool _isReversed) = optimalDeposit(_amountA, _amountB, _resA, _resB, _feeE4);
        
        if ( _isReversed ) {
            (_tokenA, _tokenB) = (_tokenB, _tokenA);
            (_amountA, _amountB) = (_amountB, _amountA);
        }
        
        _amountA -= _swapAmount;
        _amountB += _sawp(_tokenA, _tokenB, _lpAddress, _swapAmount, _feeE4, 0, address(this));

        _tokenA.safeTransfer(_lpAddress, _amountA);
        _tokenB.safeTransfer(_lpAddress, _amountB);

        _lp.mint(_to);
    }

    /// @notice mint for add liquidity
    /// @param _minterProvider token provider
    function _addLpForMint(
        address _tokenA,
        address _tokenB,
        address _lpAddress,
        uint _amountA,
        uint _amountB,
        address _minterProvider,
        address _to
    ) internal returns(uint _lpAmount) {
        IPair _lp = IPair(_lpAddress);
        (uint112 _resA, uint112 _resB,) = _lp.getReserves();
        if ( _tokenA > _tokenB ) (_resA, _resB) = (_resB, _resA);
        
        /// @dev A more，mint B
        bool _isMintA = _resA * _amountB > _resB * _amountA;
        uint _addAmount = 0;
        address _mintAddress = _tokenA;
        if (_isMintA ) {
            _addAmount = _amountB * _resA / _resB;
        }
        else {
            /// @dev A more
            _addAmount = _amountA * _resB / _resA;
            _mintAddress = _tokenB;
        }

        if (_addAmount > 0) {
            if (_minterProvider != address(this)) {
                _mintAddress.safeTransferFrom(_minterProvider, address(_lp), _addAmount);
            } else {
               if( _mintAddress == _tokenB ) _amountB += _addAmount;
               else _amountA += _addAmount;
            }
        }
        
        _tokenA.safeTransfer(address(_lp), _amountA);
        _tokenB.safeTransfer(address(_lp), _amountB);

        _lpAmount = _lp.balanceOf(_to);
        _lp.mint(_to);
        _lpAmount = _lp.balanceOf(_to) - _lpAmount;
    }

    /// @notice get back lp
    function _removeLp(
        address _lp,
        uint _liquidity,
        address _to
    ) internal {
        _lp.safeTransfer(_lp, _liquidity);
        IPair(_lp).burn(_to);
    }

    function sqrt(uint x) public pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;
    
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
    
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
    
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}