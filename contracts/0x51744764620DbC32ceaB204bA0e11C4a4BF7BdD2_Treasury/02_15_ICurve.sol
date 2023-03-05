pragma solidity ^0.8.0;

interface ICurve {
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

	function coins(uint256 i) external view returns (address);
}