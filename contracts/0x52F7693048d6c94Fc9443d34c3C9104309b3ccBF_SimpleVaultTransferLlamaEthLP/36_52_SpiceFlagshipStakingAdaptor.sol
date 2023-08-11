// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';

import { ISpiceFlagshipVault } from '../../interfaces/spice/ISpiceFlagshipVault.sol';

library SpiceFlagshipStakingAdaptor {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @notice stakes an amount of wETH into Spice's Flagship Vault
     * @param stakeData encoded data required in order to perform staking
     * @return shares Spice Flagship Vault shares received
     */
    function stake(bytes calldata stakeData) internal returns (uint256 shares) {
        (uint256 amount, address spiceFlagshipVault) = abi.decode(
            stakeData,
            (uint256, address)
        );

        IERC20(WETH).approve(spiceFlagshipVault, amount);

        shares = ISpiceFlagshipVault(spiceFlagshipVault).deposit(
            amount,
            address(this)
        );
    }

    /**
     * @notice unstakes from Spice's Flagship Vault
     * @param unstakeData encoded data required for unstaking steps
     * @param coinAmount amount of wETH received upon unstaking
     */
    function unstake(
        bytes memory unstakeData
    ) internal returns (uint256 coinAmount) {
        (uint256 vaultShares, address spiceFlagshipVault) = abi.decode(
            unstakeData,
            (uint256, address)
        );

        coinAmount = ISpiceFlagshipVault(spiceFlagshipVault).redeem(
            vaultShares,
            address(this),
            address(this)
        );
    }
}