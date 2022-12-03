pragma solidity 0.8.6;

interface IWETH {
	function withdraw(uint256 wad) external;

	function balanceOf(address guy) external view returns (uint256);

	function transferFrom(
		address src,
		address dst,
		uint256 wad
	) external returns (bool);

	function approve(address guy, uint256 wad) external returns (bool);
}