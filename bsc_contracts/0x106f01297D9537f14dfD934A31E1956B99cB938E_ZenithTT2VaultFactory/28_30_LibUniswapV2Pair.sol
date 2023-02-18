// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Math } from "../../utils/Math.sol";

import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";

library LibUniswapV2Pair
{
	using SafeERC20 for IERC20;

	struct Self {
		address pair;
		address token0;
		address token1;
		uint256[2] fee;
	}

	function _new(address _pair, uint256[2] memory _fee) internal view returns (Self memory _self)
	{
		address _token0 = IUniswapV2Pair(_pair).token0();
		address _token1 = IUniswapV2Pair(_pair).token1();
		return Self({ pair: _pair, token0: _token0, token1: _token1, fee: _fee });
	}

	function _balanceOf(Self storage _self, address _account) internal view returns (uint256 _balance)
	{
		return IERC20(_self.pair).balanceOf(_account);
	}

	function _mint2(Self storage _self, uint256 _amount0, uint256 _amount1, address _to) internal returns (uint256 _amount2)
	{
		IERC20(_self.token0).safeTransfer(_self.pair, _amount0);
		IERC20(_self.token1).safeTransfer(_self.pair, _amount1);
		return IUniswapV2Pair(_self.pair).mint(_to);
	}

	function _burn2(Self storage _self, uint256 _amount2, address _to) internal returns (uint256 _amount0, uint256 _amount1)
	{
		IERC20(_self.pair).safeTransfer(_self.pair, _amount2);
		return IUniswapV2Pair(_self.pair).burn(_to);
	}

	function _swap0(Self storage _self, uint256 _amount0, address _to) internal returns (uint256 _amount1)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		_amount1 = _calcSwapOut(_self.fee, _reserve0, _reserve1, _amount0);
		IERC20(_self.token0).safeTransfer(_self.pair, _amount0);
		IUniswapV2Pair(_self.pair).swap(0, _amount1, _to, new bytes(0));
		return _amount1;
	}

	function _swap1(Self storage _self, uint256 _amount1, address _to) internal returns (uint256 _amount0)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		_amount0 = _calcSwapOut(_self.fee, _reserve1, _reserve0, _amount1);
		IERC20(_self.token1).safeTransfer(_self.pair, _amount1);
		IUniswapV2Pair(_self.pair).swap(_amount0, 0, _to, new bytes(0));
		return _amount0;
	}

	function _zapin0(Self storage _self, uint256 _amount0, address _to) internal returns (uint256 _swapInAmount0, uint256 _swapOutAmount1)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		_swapInAmount0 = _calcZapin(_self.fee, _reserve0, _amount0);
		_swapOutAmount1 = _calcSwapOut(_self.fee, _reserve0, _reserve1, _swapInAmount0);
		IERC20(_self.token0).safeTransfer(_self.pair, _swapInAmount0);
		IUniswapV2Pair(_self.pair).swap(0, _swapOutAmount1, _to, new bytes(0));
		return (_swapInAmount0, _swapOutAmount1);
	}

	function _zapin1(Self storage _self, uint256 _amount1, address _to) internal returns (uint256 _swapInAmount1, uint256 _swapOutAmount0)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		_swapInAmount1 = _calcZapin(_self.fee, _reserve1, _amount1);
		_swapOutAmount0 = _calcSwapOut(_self.fee, _reserve1, _reserve0, _swapInAmount1);
		IERC20(_self.token1).safeTransfer(_self.pair, _swapInAmount1);
		IUniswapV2Pair(_self.pair).swap(_swapOutAmount0, 0, _to, new bytes(0));
		return (_swapInAmount1, _swapOutAmount0);
	}

	function _price1of0(Self storage _self, uint256 _amount0) internal view returns (uint256 _amount1)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		return _calcSpot(_reserve0, _reserve1, _amount0);
	}

	function _price0of1(Self storage _self, uint256 _amount1) internal view returns (uint256 _amount0)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		return _calcSpot(_reserve1, _reserve0, _amount1);
	}

	function _price0of2(Self storage _self, uint256 _amount2) internal view returns (uint256 _amount0)
	{
		(uint256 _reserve0,,) = IUniswapV2Pair(_self.pair).getReserves();
		uint256 _totalSupply = IUniswapV2Pair(_self.pair).totalSupply();
		return _calcSpot(_totalSupply, 2 * _reserve0, _amount2);
	}

	function _price1of2(Self storage _self, uint256 _amount2) internal view returns (uint256 _amount1)
	{
		(,uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		uint256 _totalSupply = IUniswapV2Pair(_self.pair).totalSupply();
		return _calcSpot(_totalSupply, 2 * _reserve1, _amount2);
	}

	function _price2of0(Self storage _self, uint256 _amount0) internal view returns (uint256 _amount2)
	{
		(uint256 _reserve0,,) = IUniswapV2Pair(_self.pair).getReserves();
		uint256 _totalSupply = IUniswapV2Pair(_self.pair).totalSupply();
		return _calcSpot(_reserve0, _totalSupply, _amount0) / 2;
	}

	function _price2of1(Self storage _self, uint256 _amount1) internal view returns (uint256 _amount2)
	{
		(,uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		uint256 _totalSupply = IUniswapV2Pair(_self.pair).totalSupply();
		return _calcSpot(_reserve1, _totalSupply, _amount1) / 2;
	}

	function _calcSwapOut0(Self storage _self, uint256 _amount0) internal view returns (uint256 _amount1)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		return _calcSwapOut(_self.fee, _reserve0, _reserve1, _amount0);
	}

	function _calcSwapOut1(Self storage _self, uint256 _amount1) internal view returns (uint256 _amount0)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_self.pair).getReserves();
		return _calcSwapOut(_self.fee, _reserve1, _reserve0, _amount1);
	}

	function _averagePrice1of0(Self storage _self, uint256 _price0Cumulative0Last, uint256 _blockTimestampLast, uint256 _amount0) internal view returns (uint256 _amount1)
	{
		return ((_price0CumulativeLatest(_self) - _price0Cumulative0Last) * _amount0 / (block.timestamp - _blockTimestampLast)) >> 112;
	}

	function _averagePrice0of1(Self storage _self, uint256 _price1Cumulative0Last, uint256 _blockTimestampLast, uint256 _amount1) internal view returns (uint256 _amount0)
	{
		return ((_price1CumulativeLatest(_self) - _price1Cumulative0Last) * _amount1 / (block.timestamp - _blockTimestampLast)) >> 112;
	}

	function _price0CumulativeLatest(Self storage _self) internal view returns (uint256 _price0Cumulative)
	{
		_price0Cumulative = IUniswapV2Pair(_self.pair).price0CumulativeLast();
		(uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestamp) = IUniswapV2Pair(_self.pair).getReserves();
		if (block.timestamp > _blockTimestamp) {
			_price0Cumulative += ((_reserve1 << 112) / _reserve0) * (block.timestamp - _blockTimestamp);
		}
		return _price0Cumulative;
	}

	function _price1CumulativeLatest(Self storage _self) internal view returns (uint256 _price1Cumulative)
	{
		_price1Cumulative = IUniswapV2Pair(_self.pair).price1CumulativeLast();
		(uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestamp) = IUniswapV2Pair(_self.pair).getReserves();
		if (block.timestamp > _blockTimestamp) {
			_price1Cumulative += ((_reserve0 << 112) / _reserve1) * (block.timestamp - _blockTimestamp);
		}
		return _price1Cumulative;
	}

	function _calcSpot(uint256 _reserveIn, uint256 _reserveOut, uint256 _amountIn) private pure returns (uint256 _amountOut)
	{
		return _reserveOut * _amountIn / _reserveIn;
	}

	function _calcZapin(uint256[2] memory _fee, uint256 _reserveIn, uint256 _amountIn) private pure returns (uint256 _amountSwapIn)
	{
		return (Math._sqrt(_reserveIn * (_amountIn * 4 * _fee[0] * _fee[1] + _reserveIn * (_fee[0] * _fee[0] + _fee[1] * (_fee[1] + 2 * _fee[0])))) - _reserveIn * (_fee[1] + _fee[0])) / (2 * _fee[1]);
	}

	function _calcSwapOut(uint256[2] memory _fee, uint256 _reserveIn, uint256 _reserveOut, uint256 _amountIn) private pure returns (uint256 _amountOut)
	{
		uint256 _amountInWithFee = _amountIn * _fee[0];
		return (_reserveOut * _amountInWithFee) / (_reserveIn * _fee[1] + _amountInWithFee);
	}
}