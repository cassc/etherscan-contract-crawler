// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';

import { JPEGDStakingAdaptor as staking } from '../staking/JPEGDStakingAdaptor.sol';
import { JPEGDAdaptorStorage as s } from '../storage/JPEGDAdaptorStorage.sol';
import { IStableSwap } from '../../interfaces/curve/IStableSwap.sol';
import { ITriCrypto } from '../../interfaces/curve/ITriCrypto.sol';
import { INFTVault } from '../../interfaces/jpegd/INFTVault.sol';
import { INFTEscrow } from '../../interfaces/jpegd/INFTEscrow.sol';
import { IVault } from '../../interfaces/jpegd/IVault.sol';

library JPEGDLendingAdaptor {
    /**
     * @notice thrown when attempting to borrow after target LTV amount is reached
     */
    error JPEGD__TargetLTVReached();

    /**
     * @notice thrown when insufficient amount of debt is repaid after repayLoan call
     */
    error JPEGD__RepaymentInsufficient();

    /**
     * @notice thrown when the transfer of an asset to JPEGD NFT Vault helper contract fails
     */
    error JPEGD__LowLevelTransferFailed();

    /**
     * @notice borrows JPEGD stablecoin in exchange for collaterlizing an ERC721 asset
     * @param collateralizationData encoded data needed to collateralize the ERC721 asset
     * @param ltvBufferBP loan-to-value buffer value in basis points
     * @param ltvDeviationBP loan-to-value deviation value in basis points
     * @return collection ERC721 collection address
     * @return tokenId id of ERC721 asset
     * @return amount amount of JPEGD stablecoin token received for the collateralized ERC721 asset
     */
    function collateralizeERC721Asset(
        bytes calldata collateralizationData,
        uint16 ltvBufferBP,
        uint16 ltvDeviationBP
    ) internal returns (address collection, uint256 tokenId, uint256 amount) {
        (
            address nftVault,
            uint256 id,
            uint256 borrowAmount,
            bool insure,
            bool hasHelper,
            bool isDirectTransfer,
            bytes memory transferData
        ) = abi.decode(
                collateralizationData,
                (address, uint256, uint256, bool, bool, bool, bytes)
            );

        address token = INFTVault(nftVault).stablecoin();
        address jpegdCollection = INFTVault(nftVault).nftContract();
        address transferTarget = hasHelper ? jpegdCollection : nftVault;
        collection = hasHelper
            ? INFTEscrow(jpegdCollection).nftContract()
            : jpegdCollection;
        tokenId = id;

        uint256 creditLimit = INFTVault(nftVault).getCreditLimit(
            address(this),
            tokenId
        );
        uint256 targetLTV = creditLimit -
            (creditLimit * (ltvBufferBP + ltvDeviationBP)) /
            s.BASIS_POINTS;

        if (INFTVault(nftVault).positionOwner(tokenId) != address(0)) {
            uint256 debt = totalDebt(nftVault, tokenId);

            if (borrowAmount + debt > targetLTV) {
                if (targetLTV < debt) {
                    revert JPEGD__TargetLTVReached();
                }
                borrowAmount = targetLTV - debt;
            }
        } else {
            if (borrowAmount > targetLTV) {
                borrowAmount = targetLTV;
            }

            if (isDirectTransfer) {
                IERC721(collection).approve(transferTarget, tokenId);
            } else {
                (bool success, ) = collection.call(transferData);

                if (!success) {
                    revert JPEGD__LowLevelTransferFailed();
                }
            }
        }

        uint256 oldBalance = IERC20(token).balanceOf(address(this));

        INFTVault(nftVault).borrow(tokenId, borrowAmount, insure);

        amount = IERC20(token).balanceOf(address(this)) - oldBalance;
    }

    /**
     * @notice liquidates all staked tokens in order to pay back loan, retrieves collateralized asset
     * @param closeData encoded data required to close JPEGD position
     * @return receivedETH amount of ETH received after exchanging surplus
     * @return collection address of underlying ERC721 contract
     * @param id tokenId relating to loan position
     */
    function closePosition(
        bytes calldata closeData
    ) internal returns (uint256 receivedETH, address collection, uint256 id) {
        (
            uint256 tokenId,
            uint256 minCoin,
            uint256 minETH,
            uint256 minUSDT,
            uint256 poolInfoIndex,
            address nftVault,
            bool isPETH,
            bool hasHelper
        ) = abi.decode(
                closeData,
                (
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    bool,
                    bool
                )
            );

        address coin;
        address vault;
        address curvePool;
        int128 curveIndex;

        if (isPETH) {
            coin = s.PETH;
            vault = s.PETH_VAULT;
            curvePool = s.CURVE_PETH_POOL;
            curveIndex = s.STABLE_PETH_INDEX;
        } else {
            coin = s.PUSD;
            vault = s.PUSD_VAULT;
            curvePool = s.CURVE_PUSD_POOL;
            curveIndex = s.STABLE_PUSD_INDEX;
        }

        uint256 debt = totalDebt(nftVault, tokenId);
        uint256[2] memory amounts;
        amounts[uint256(uint128(curveIndex))] = debt;

        uint256 coinAmount = staking.unstake(
            abi.encode(
                queryVaultTokensForCoins(amounts, curvePool, vault),
                minCoin,
                poolInfoIndex,
                curveIndex,
                isPETH
            )
        );

        IERC20(coin).approve(nftVault, debt);
        INFTVault(nftVault).repay(tokenId, debt);
        INFTVault(nftVault).closePosition(tokenId);

        uint256 surplus = coinAmount - debt;

        receivedETH = swapCoin(coin, curvePool, surplus, minETH, minUSDT);
        id = tokenId;
        address jpegdCollection = INFTVault(nftVault).nftContract();
        collection = hasHelper
            ? INFTEscrow(jpegdCollection).nftContract()
            : jpegdCollection;
    }

    /**
     * @notice makes a debt payment for a collateralized NFT
     * @param repayData encoded data required for debt repayment
     * @return paidDebt amount of debt repaid
     */
    function repayLoan(
        bytes calldata repayData
    ) internal returns (uint256 paidDebt) {
        (
            uint256 amount,
            uint256 minCoinOut,
            uint256 poolInfoIndex,
            uint256 tokenId,
            address nftVault,
            bool isPETH
        ) = abi.decode(
                repayData,
                (uint256, uint256, uint256, uint256, address, bool)
            );

        address coin;
        address vault;
        address curvePool;
        int128 curveIndex;

        if (isPETH) {
            coin = s.PETH;
            vault = s.PETH_VAULT;
            curvePool = s.CURVE_PETH_POOL;
            curveIndex = s.STABLE_PETH_INDEX;
        } else {
            coin = s.PUSD;
            vault = s.PUSD_VAULT;
            curvePool = s.CURVE_PUSD_POOL;
            curveIndex = s.STABLE_PUSD_INDEX;
        }
        uint256[2] memory amounts;
        amounts[uint256(uint128(curveIndex))] = amount;

        paidDebt = staking.unstake(
            abi.encode(
                queryVaultTokensForCoins(amounts, curvePool, vault),
                minCoinOut,
                poolInfoIndex,
                curveIndex,
                isPETH
            )
        );

        if (amount > paidDebt) {
            revert JPEGD__RepaymentInsufficient();
        }

        IERC20(coin).approve(nftVault, paidDebt);
        INFTVault(nftVault).repay(tokenId, paidDebt);
    }

    /**
     * @notice makes loan repayment without unstaking
     * @param directRepayData encoded data required for direct loan repayment
     */
    function directRepayLoan(
        bytes calldata directRepayData
    ) internal returns (uint256 paidDebt) {
        (address nftVault, uint256 tokenId, uint256 amount, bool isPETH) = abi
            .decode(directRepayData, (address, uint256, uint256, bool));

        address coin = isPETH ? s.PETH : s.PUSD;

        IERC20(coin).approve(nftVault, amount);
        INFTVault(nftVault).repay(tokenId, amount);

        paidDebt = amount;
    }

    /**
     * @notice returns amount of JPEGD Vault LP shares needed to be burnt during unstaking
     * to result in a given amount of JPEGD stablecoins
     * @param amounts array of token amounts to receive upon curveLP token burn.
     * @param curvePool curve pool where JPEGD token - token are the underlying tokens
     * @param vault address of JPEGD Vault to withdraw from
     * @return vaultTokens required amount of JPEGD Vault
     */
    function queryVaultTokensForCoins(
        uint256[2] memory amounts,
        address curvePool,
        address vault
    ) internal view returns (uint256 vaultTokens) {
        //does not account for fees, not meant for precise calculations
        //leads to some inaccuracy in later conversion
        uint256 curveLP = IStableSwap(curvePool).calc_token_amount(
            amounts,
            false
        );

        //account for fees
        uint256 curveLPAccountingFee = (curveLP * s.CURVE_BASIS) /
            (s.CURVE_BASIS - s.CURVE_FEE);

        vaultTokens =
            (curveLPAccountingFee * 10 ** IVault(vault).decimals()) /
            IVault(vault).exchangeRate();
    }

    /**
     * @notice returns either total debt or debt interest depending on queryData for a given tokenId
     * on a given JPEGD NFT vault
     * @param queryData encoded data required to query the debt on JPEGD NFT vault
     * @return debt either total debt or debt interest for given tokenId
     */
    function queryDebt(
        bytes calldata queryData
    ) internal view returns (uint256 debt) {
        (address nftVault, uint256 tokenId, bool total) = abi.decode(
            queryData,
            (address, uint256, bool)
        );

        if (total) {
            debt = totalDebt(nftVault, tokenId);
        } else {
            debt = INFTVault(nftVault).getDebtInterest(tokenId);
        }
    }

    /**
     * @notice transfers JPEG tokens equal to yield of account to account
     * @param account address to transfer JPEG tokens to
     */
    function userClaim(address account) internal {
        s.Layout storage l = s.layout();

        uint256 yield = l.userJPEGYield[account];
        delete l.userJPEGYield[account];

        IERC20(s.JPEG).transfer(account, yield);
    }

    /**
     * @notice updates yield of an account without performing transfers
     * @param account account address to record for
     * @param yieldFeeBP discounted yield fee in basis points
     */
    function updateUserRewards(
        address account,
        uint256 shards,
        uint16 yieldFeeBP
    ) internal {
        s.Layout storage l = s.layout();

        uint256 yieldPerShard = l.cumulativeJPEGPerShard -
            l.jpegDeductionsPerShard[account];

        if (yieldPerShard > 0) {
            uint256 totalYield = yieldPerShard * shards;
            uint256 fee = (totalYield * yieldFeeBP) / s.BASIS_POINTS;

            l.jpegDeductionsPerShard[account] += yieldPerShard;
            l.accruedJPEGFees += fee;
            l.userJPEGYield[account] += totalYield - fee;
        }
    }

    /**
     * @notice withdraws JPEG protocol fees and sends to account
     * @param account address of account to send fees to
     * @return fees amount of JPEG fees
     */
    function withdrawFees(address account) internal returns (uint256 fees) {
        s.Layout storage l = s.layout();

        fees = l.accruedJPEGFees;
        delete l.accruedJPEGFees;

        IERC20(s.JPEG).transfer(account, fees);
    }

    /**
     * @notice returns the total JPEG an account may claim
     * @param account account address
     * @param shards shard balance of account
     * @param yieldFeeBP discounted yield fee in basis points
     * @return yield total JPEG claimable
     */
    function userRewards(
        address account,
        uint256 shards,
        uint16 yieldFeeBP
    ) internal view returns (uint256 yield) {
        s.Layout storage l = s.layout();
        uint256 yieldPerShard = l.cumulativeJPEGPerShard -
            l.jpegDeductionsPerShard[account];

        uint256 unclaimedYield = yieldPerShard * shards;
        uint256 yieldFee = (unclaimedYield * yieldFeeBP) / s.BASIS_POINTS;
        yield = l.userJPEGYield[account] + unclaimedYield - yieldFee;
    }

    /**
     * @notice returns the accrued JPEG protocol fees
     * @return fees total accrued JPEG protocol fees
     */
    function accruedJPEGFees() internal view returns (uint256 fees) {
        fees = s.layout().accruedJPEGFees;
    }

    /**
     * @notice returns the cumulative JPEG amount accrued per shard
     * @return amount cumulative JPEG amount accrued per shard
     */
    function cumulativeJPEGPerShard() internal view returns (uint256 amount) {
        amount = s.layout().cumulativeJPEGPerShard;
    }

    /**
     * @notice returns total debt owed to JPEGD NFT vault for a given token
     * @param nftVault address of JPEGD NFT vault
     * @param tokenId id of token position pertains to
     * @return debt total debt owed
     */
    function totalDebt(
        address nftVault,
        uint256 tokenId
    ) private view returns (uint256 debt) {
        debt =
            INFTVault(nftVault).getDebtInterest(tokenId) +
            INFTVault(nftVault).positions(tokenId).debtPrincipal;
    }

    /**
     * @notice swaps JPEGD stablecoin for ETH via curve pools
     * @param coin address of PETH/PUSD
     * @param coinAmount amoutn of PETH/PUSD
     * @param minETH minimum ETH to receive on final exchange
     * @param minUSDT minimum USDT to receive on intermediary exchange in PUSD => USDT => ETH
     */
    function swapCoin(
        address coin,
        address curvePool,
        uint256 coinAmount,
        uint256 minETH,
        uint256 minUSDT
    ) private returns (uint256 receivedETH) {
        if (coin == s.PETH) {
            IERC20(coin).approve(curvePool, coinAmount);
            receivedETH = IStableSwap(curvePool).exchange(
                int128(1), //PETH position in curve pool
                int128(0), //ETH position in cruve pool
                coinAmount,
                minETH
            );
        } else {
            IERC20(coin).approve(curvePool, coinAmount);

            uint256 receivedUSDT = IStableSwap(curvePool).exchange_underlying(
                int128(0), //PUSD position in curve pool
                int128(3), //USDT position in curve pool
                coinAmount,
                minUSDT
            );

            receivedETH = ITriCrypto(s.TRI_CRYPTO_POOL).exchange(
                int128(0), //USDT position in curve tricrypto pool
                int128(2), //WETH position in cruve tricrypto pool
                receivedUSDT,
                minETH,
                true
            );
        }
    }
}