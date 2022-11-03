// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICurveZapper {
	function exchange(address _pool, uint256 i, uint256 j, uint256 _dx, uint256 _min_dy) external returns(uint256);
	function get_dy(address _pool, uint256 i, uint256 j, uint256 _dx) external view returns(uint256);
}