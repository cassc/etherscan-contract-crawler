// SPDX-License-Identifier: MIT

interface IVault {
	function token() external view returns (address);

	function underlying() external view returns (address);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function controller() external view returns (address);

	function governance() external view returns (address);

	function getPricePerFullShare() external view returns (uint256);

	function deposit() external returns (uint256);

	function deposit(uint256) external returns (uint256);

	function deposit(uint256, address) external returns (uint256);

	function depositAll() external;

	function withdraw(uint256) external;

	function withdrawAll() external;
}