// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "IERC20Metadata.sol";

interface IERC20Mint is IERC20Metadata {
	function mint(address _for, uint256 _amount) external;
}