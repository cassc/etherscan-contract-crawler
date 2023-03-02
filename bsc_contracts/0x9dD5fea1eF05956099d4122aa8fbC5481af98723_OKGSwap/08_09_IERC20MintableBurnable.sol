// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
	@title IERC20MintBurnable
	@dev IERC20 that can be mint or burn without supply limit
 */
interface IERC20MintableBurnable is IERC20 {
	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function mint(address to, uint256 amount) external;
}