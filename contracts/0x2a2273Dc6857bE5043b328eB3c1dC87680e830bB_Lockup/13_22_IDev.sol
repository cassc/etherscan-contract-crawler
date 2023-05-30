// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface IDev {
	function deposit(address _to, uint256 _amount) external returns (bool);

	function depositFrom(
		address _from,
		address _to,
		uint256 _amount
	) external returns (bool);

	function fee(address _from, uint256 _amount) external returns (bool);
}