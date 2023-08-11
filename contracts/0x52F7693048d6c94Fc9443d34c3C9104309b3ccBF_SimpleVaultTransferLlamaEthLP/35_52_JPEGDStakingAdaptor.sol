// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';

import { JPEGDAdaptorStorage as s } from '../storage/JPEGDAdaptorStorage.sol';
import { IStableSwap } from '../../interfaces/curve/IStableSwap.sol';
import { ITriCrypto } from '../../interfaces/curve/ITriCrypto.sol';
import { INFTVault } from '../../interfaces/jpegd/INFTVault.sol';
import { ILPFarming } from '../../interfaces/jpegd/ILPFarming.sol';
import { IVault } from '../../interfaces/jpegd/IVault.sol';

library JPEGDStakingAdaptor {
    /**
     * @notice stakes an amount of coins into Curve_LP, then into JPEGD Vault and then into JPEGD LPFarming
     * @param stakeData encoded data required in order to perform staking
     * @return shares JPEGD Vault token amount deposited in LPFarming
     */
    function stake(bytes calldata stakeData) internal returns (uint256 shares) {
        (
            uint256 amount,
            uint256 minCurveLP,
            uint256 poolInfoIndex,
            uint256[2] memory amounts,
            bool isPETH
        ) = abi.decode(
                stakeData,
                (uint256, uint256, uint256, uint256[2], bool)
            );

        address coin;
        address curvePool;
        address vault;

        if (isPETH) {
            coin = s.PETH;
            curvePool = s.CURVE_PETH_POOL;
            vault = s.PETH_VAULT;
        } else {
            coin = s.PUSD;
            curvePool = s.CURVE_PUSD_POOL;
            vault = s.PUSD_VAULT;
        }

        IERC20(coin).approve(curvePool, amount);
        uint256 curveLP = IStableSwap(curvePool).add_liquidity(
            amounts,
            minCurveLP
        );

        IERC20(curvePool).approve(vault, curveLP);
        shares = IVault(vault).deposit(address(this), curveLP);

        IERC20(ILPFarming(s.LP_FARMING).poolInfo(poolInfoIndex).lpToken)
            .approve(s.LP_FARMING, shares);

        ILPFarming(s.LP_FARMING).deposit(poolInfoIndex, shares);
    }

    /**
     * @notice unstakes from JPEGD LPFarming, then from JPEGD vault, then from curve LP
     * @param unstakeData encoded data required for unstaking steps
     * @param coinAmount amount of JPEGD stablecoin received upon unstaking
     */
    function unstake(
        bytes memory unstakeData
    ) internal returns (uint256 coinAmount) {
        (
            uint256 vaultTokens,
            uint256 minCoinOut,
            uint256 poolInfoIndex,
            int128 curveIndex, //can't use constant directly - may want to unstake either token
            bool isPETH
        ) = abi.decode(unstakeData, (uint256, uint256, uint256, int128, bool));

        ILPFarming(s.LP_FARMING).withdraw(poolInfoIndex, vaultTokens);

        address vault;
        address curvePool;

        if (isPETH) {
            vault = s.PETH_VAULT;
            curvePool = s.CURVE_PETH_POOL;
        } else {
            vault = s.PUSD_VAULT;
            curvePool = s.CURVE_PUSD_POOL;
        }

        uint256 curveLP = IVault(vault).withdraw(
            address(this),
            IERC20(ILPFarming(s.LP_FARMING).poolInfo(poolInfoIndex).lpToken)
                .balanceOf(address(this))
        );

        coinAmount = IStableSwap(curvePool).remove_liquidity_one_coin(
            curveLP,
            curveIndex,
            minCoinOut
        );
    }

    /**
     * @notice unstakes from JPEGD LPFarming, then from JPEGD vault, then from curve LP and converts
     * to desired token of curveLP
     * @param unstakeData encoded data required for unstaking steps
     * @param totalSupply total supply of shards
     * @return receivedToken token amount received after unstaking
     * @return receivedJPEG amount JPEG token received after claiming
     */
    function provideYield(
        bytes calldata unstakeData,
        uint256 totalSupply
    ) internal returns (uint256 receivedToken, uint256 receivedJPEG) {
        receivedToken = unstake(unstakeData);
        (, , uint256 poolInfoIndex, , ) = abi.decode(
            unstakeData,
            (uint256, uint256, uint256, int128, bool)
        );
        receivedJPEG = ILPFarming(s.LP_FARMING).pendingReward(
            poolInfoIndex,
            address(this)
        );

        ILPFarming(s.LP_FARMING).claim(poolInfoIndex);

        s.layout().cumulativeJPEGPerShard += receivedJPEG / totalSupply;
    }
}