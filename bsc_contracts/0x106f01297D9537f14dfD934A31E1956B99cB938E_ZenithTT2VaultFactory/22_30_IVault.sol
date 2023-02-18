// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { IERC20MetadataUpgradeable as IERC20Metadata } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IVault is IERC20Metadata
{
	function tokens() external view returns (address[] memory _tokens);
	function totalReserve(address _token) external view returns (uint256 _totalReserve);

	function deposit(address _token, uint256 _amount, uint256 _minShares) external returns (uint256 _shares);
	function withdraw(address _token, uint256 _shares, uint256 _minAmount) external returns (uint256 _amount);
	function compound(uint256 _minShares) external returns (uint256 _shares);
}