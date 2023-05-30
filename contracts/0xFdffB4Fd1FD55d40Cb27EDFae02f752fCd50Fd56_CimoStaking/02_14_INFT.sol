// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";

interface INFT is IERC721 {
	function getMultiplierForTokenID(uint256 _tokenID) external view returns (uint256);
}