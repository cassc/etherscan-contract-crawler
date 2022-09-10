// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IMockSynth
{
	function token() external view returns (address _token);
	function fund() external view returns (uint256 _fund);
	function debt() external view returns (uint256 _debt);
	function balanceOf(address _account) external view returns (uint256 _balance);

	function donate(uint256 _amount) external;
	function collect(uint256 _amount) external;
	function deposit(address _account, uint256 _amount) external;
	function withdraw(address _account, uint256 _amount) external;
}