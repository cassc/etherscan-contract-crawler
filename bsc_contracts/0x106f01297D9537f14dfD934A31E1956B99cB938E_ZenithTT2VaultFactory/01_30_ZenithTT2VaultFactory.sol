// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { VaultFactoryBase } from "../../base/VaultFactoryBase.sol";

import { ZenithTT2Vault } from "./ZenithTT2Vault.sol";

contract ZenithTT2VaultFactory is VaultFactoryBase
{
	function _newVault() internal override returns (address _vault)
	{
		return address(new ZenithTT2Vault());
	}
}