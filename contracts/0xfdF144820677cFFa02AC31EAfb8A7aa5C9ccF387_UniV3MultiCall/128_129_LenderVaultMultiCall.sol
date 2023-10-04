// SPDX-License-Identifier: GPL-3.0
// This contract was inspired from multicall2 repo from makerdao and handles the specific uni-v3 use case where
// we need to call a contract pool (one target address) and the only change in quote array is the amount in.
// This saves space compared to the more general multicall2 aggregate function.
// @dev: this contract is a helper contract and should only be used for backend jobs

pragma solidity 0.8.19;

import {ILenderVaultImpl} from "../peer-to-peer/interfaces/ILenderVaultImpl.sol";

contract LenderVaultMultiCall {
    struct BalancesAndLockedAmounts {
        uint256[] balances;
        uint256[] lockedAmounts;
    }

    function getTokenBalancesAndLockedAmountsForMultipleVaults(
        address[] calldata vaults,
        address[] calldata tokens
    ) external view returns (BalancesAndLockedAmounts[] memory results) {
        uint256[] memory allZeroArr = new uint256[](tokens.length);
        results = new BalancesAndLockedAmounts[](vaults.length);
        for (uint256 i = 0; i < vaults.length; ) {
            try
                ILenderVaultImpl(vaults[i]).getTokenBalancesAndLockedAmounts(
                    tokens
                )
            returns (
                uint256[] memory _balances,
                uint256[] memory _lockedAmounts
            ) {
                results[i] = BalancesAndLockedAmounts({
                    balances: _balances,
                    lockedAmounts: _lockedAmounts
                });
            } catch {
                results[i] = BalancesAndLockedAmounts({
                    balances: allZeroArr,
                    lockedAmounts: allZeroArr
                });
            }
            unchecked {
                ++i;
            }
            if (gasleft() < 1_000_000) {
                break;
            }
        }
    }
}