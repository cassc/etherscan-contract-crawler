// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface SectorErrors {
	error NotImplemented();
	error MaxTvlReached();
	error StrategyHasBalance();
	error MinLiquidity();
	error OnlyVault();
}