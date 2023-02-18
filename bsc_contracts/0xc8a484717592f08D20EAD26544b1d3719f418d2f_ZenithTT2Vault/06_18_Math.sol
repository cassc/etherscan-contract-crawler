// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

library Math
{
	function _sqrt(uint256 _x) internal pure returns (uint256 _y)
	{
		_y = _x;
		uint256 _z = (_x + 1) / 2;
		while (_z < _y) {
			_y = _z;
			_z = (_x / _z + _z) / 2;
		}
		return _y;
	}

	function _exp(uint256 _x, uint256 _n) internal pure returns (uint256 _y)
	{
		_y = 1e18;
		while (_n > 0) {
			if (_n & 1 != 0) _y = _y * _x / 1e18;
			_n >>= 1;
			_x = _x * _x / 1e18;
		}
		return _y;
	}
}