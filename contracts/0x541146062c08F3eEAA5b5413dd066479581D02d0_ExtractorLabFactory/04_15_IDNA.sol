// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDNA is IERC1155 {
	function isCooledDown(uint256) external view returns (bool);

	function runExtraction(uint256 mutantId, uint16 boostId) external payable;

	function completeExtraction(uint256 mutantId) external;

	function extractionCost() external view returns (uint256);

	function getBoostCost(uint256 index) external view returns (uint256);
}