// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";

// Info of each pool.
struct PoolInfo
{
	IERC20 lpToken; // Address of LP token contract.
	uint256 allocPoint; // How many allocation points assigned to this pool. FMNs to distribute per block.
	uint256 lastRewardBlock; // Last block number that FMNs distribution occurs.
	uint256 accFermionPerShare; // Accumulated FMNs per share, times _ACC_FERMION_PRECISSION. See below.
	uint256 initialLock; // Block until withdraw from the pool is not possible.
}