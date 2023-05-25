pragma solidity ^0.8.0;

interface IwTBTPoolV2Permission {
	function getUnderlyingByCToken(uint256) external view returns (uint256);

	function getInitalCtokenToUnderlying() external view returns (uint256);

	function mintFor(uint256, address) external;

	function mint(uint256) external;
}