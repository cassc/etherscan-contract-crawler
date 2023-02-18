// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVaultFactory
{
	function taggedVault(address _account, bytes32 _tag) external view returns (address _vault, bool _exists);
	function createVault(bytes32 _tag, string memory _name, string memory _symbol, bytes memory _data) external returns (address _vault);
}