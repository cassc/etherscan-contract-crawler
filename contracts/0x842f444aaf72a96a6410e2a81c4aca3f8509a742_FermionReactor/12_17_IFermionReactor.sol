// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";

import "./IFermion.sol";
import "./IMagneticFieldGenerator.sol";

interface IFermionReactor is IOwnable
{
	event Buy(address indexed user, uint256 ethAmount, uint256 fermionAmount);

	function buyFermion() external payable;
	
	function disable() external;
	function transferOtherERC20Token(IERC20 token) external returns(bool);

	function getFermionAddress() external view returns(IFermion);
	function getLowerEthLimit() external view returns(uint256);
	function getRate() external view returns(uint256);
	function getUpperEthLimit() external view returns(uint256);
	function isActive() external view returns(bool);
}