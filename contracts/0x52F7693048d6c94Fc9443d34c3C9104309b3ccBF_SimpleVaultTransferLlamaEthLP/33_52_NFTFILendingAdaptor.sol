// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IWETH } from '@solidstate/contracts/interfaces/IWETH.sol';

import { NFTFILoanData as LoanData } from './NFTFILoanData.sol';
import { SpiceFlagshipStakingAdaptor as SpiceFlagshipStaking } from '../staking/SpiceFlagshipStakingAdaptor.sol';
import { IDirectLoanFixedOffer as INFTEscrow } from '../../interfaces/nftfi/IDirectLoanFixedOffer.sol';
import { ISpiceFlagshipVault } from '../../interfaces/spice/ISpiceFlagshipVault.sol';
import { ISimpleVaultInternal } from '../../simple/ISimpleVaultInternal.sol';

library NFTFILendingAdaptor {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /**
     * @notice thrown when debt exceeds unstaked token amount during closePosition call
     */
    error NFTFI__DebtExceedsTokenAmount();

    /**
     * @notice thrown when insufficient amount of debt is repaid during repayLoan call
     */
    error NFTFI__RepaymentInsufficient();

    /**
     * @notice liquidates all staked tokens in order to pay back loan and retrieve collateralized asset
     * @param closeData encoded data required to close NFTFI position
     * @return receivedETH amount of ETH received after exchanging surplus
     * @return collection address of underlying NFT collection
     * @return tokenId tokenId relating to loan position
     */
    function closePosition(
        bytes calldata closeData
    )
        internal
        returns (uint256 receivedETH, address collection, uint256 tokenId)
    {
        (
            ISimpleVaultInternal.StakingAdaptor stakingAdaptor,
            uint32 loanId,
            address nftfiEscrowAddress,
            address stakingVendorAddress // the vault or pool being used for staking
        ) = abi.decode(
                closeData,
                (ISimpleVaultInternal.StakingAdaptor, uint32, address, address)
            );

        uint256 unstakedTokenAmount;

        LoanData.LoanTerms memory loanTerms = INFTEscrow(nftfiEscrowAddress)
            .loanIdToLoan(loanId);

        uint256 debt = loanTerms.maximumRepaymentAmount;
        address loanERC20Denomination = loanTerms.loanERC20Denomination;

        if (
            stakingAdaptor == ISimpleVaultInternal.StakingAdaptor.SPICE_FLAGSHIP
        ) {
            uint256 vaultShares = ISpiceFlagshipVault(stakingVendorAddress) // staking vendor should be the Spice Flagship Vault
                .balanceOf(address(this));

            unstakedTokenAmount = SpiceFlagshipStaking.unstake(
                abi.encode(vaultShares, stakingVendorAddress)
            );

            uint256 surplusWETH = unstakedTokenAmount - debt;

            IWETH(WETH).withdraw(surplusWETH);

            receivedETH = surplusWETH;
        }

        if (debt > unstakedTokenAmount) {
            revert NFTFI__DebtExceedsTokenAmount();
        }

        IERC20(loanERC20Denomination).approve(nftfiEscrowAddress, debt);

        INFTEscrow(nftfiEscrowAddress).payBackLoan(loanId);

        collection = loanTerms.nftCollateralContract;
        tokenId = loanTerms.nftCollateralId;
    }

    /**
     * @notice borrows an Nftfi-supported loan principal asset in exchange for collaterlizing an ERC721 asset
     * @param collateralizationData encoded data needed to collateralize the ERC721 asset
     * @return collection ERC721 collection address
     * @return tokenId id of ERC721 asset
     * @return amount amount of loan principal asset received for the collateralized ERC721 asset
     */
    function collateralizeERC721Asset(
        bytes calldata collateralizationData
    ) internal returns (address collection, uint256 tokenId, uint256 amount) {
        (
            address nftfiEscrowAddress,
            LoanData.Offer memory offer,
            LoanData.Signature memory signature,
            LoanData.BorrowerSettings memory borrowerSettings
        ) = abi.decode(
                collateralizationData,
                (
                    address,
                    LoanData.Offer,
                    LoanData.Signature,
                    LoanData.BorrowerSettings
                )
            );

        collection = offer.nftCollateralContract;
        tokenId = offer.nftCollateralId;

        IERC721(collection).approve(nftfiEscrowAddress, tokenId);

        uint256 oldBalance = IERC20(offer.loanERC20Denomination).balanceOf(
            address(this)
        );

        INFTEscrow(nftfiEscrowAddress).acceptOffer(
            offer,
            signature,
            borrowerSettings
        );

        amount =
            IERC20(offer.loanERC20Denomination).balanceOf(address(this)) -
            oldBalance;
    }

    /**
     * @notice makes loan repayment without unstaking
     * @param directRepayData encoded data required for direct loan repayment
     * @return paidDebt amount of debt repaid
     */
    function directRepayLoan(
        bytes calldata directRepayData
    ) internal returns (uint256 paidDebt) {
        (
            uint32 loanId,
            uint256 fullPayOffAmount,
            address loanERC20Denomination,
            address nftfiEscrowAddress
        ) = abi.decode(directRepayData, (uint32, uint256, address, address));

        IERC20(loanERC20Denomination).approve(
            nftfiEscrowAddress,
            fullPayOffAmount
        );

        INFTEscrow(nftfiEscrowAddress).payBackLoan(loanId);

        paidDebt = fullPayOffAmount;
    }

    /**
     * @notice returns either total debt or debt interest depending on queryData for a given loan
     * using a given loanId
     * @param queryData encoded data required to query the debt on the NFTFI escrow contract
     * @return debt either total debt or debt interest for given loanId
     */
    function queryDebt(
        bytes calldata queryData
    ) internal view returns (uint256 debt) {
        (address nftfiEscrowAddress, uint32 loanId, bool totalDebt) = abi
            .decode(queryData, (address, uint32, bool));

        LoanData.LoanTerms memory loanTerms = INFTEscrow(nftfiEscrowAddress)
            .loanIdToLoan(loanId);

        if (totalDebt) {
            debt = loanTerms.maximumRepaymentAmount;
        } else {
            debt =
                loanTerms.maximumRepaymentAmount -
                loanTerms.loanPrincipalAmount;
        }
    }

    /**
     * @notice makes loan repayment by unstaking
     * @param repayData encoded data required for loan repayment
     * @return paidDebt amount of debt repaid
     */
    function repayLoan(
        bytes calldata repayData
    ) internal returns (uint256 paidDebt) {
        (
            ISimpleVaultInternal.StakingAdaptor stakingAdaptor,
            uint32 loanId,
            uint256 amountToUnstake, // this can be a token amount or vault shares
            uint256 fullPayOffAmount,
            address loanERC20Denomination,
            address nftfiEscrowAddress,
            address stakingVendorAddress // the vault or pool being used for staking
        ) = abi.decode(
                repayData,
                (
                    ISimpleVaultInternal.StakingAdaptor,
                    uint32,
                    uint256,
                    uint256,
                    address,
                    address,
                    address
                )
            );

        uint256 unstakedTokenAmount;

        if (
            stakingAdaptor == ISimpleVaultInternal.StakingAdaptor.SPICE_FLAGSHIP
        ) {
            unstakedTokenAmount = SpiceFlagshipStaking.unstake(
                abi.encode(amountToUnstake, stakingVendorAddress) // staking vendor should be the Spice Flagship Vault
            );
        }

        if (fullPayOffAmount > unstakedTokenAmount) {
            revert NFTFI__RepaymentInsufficient();
        }

        IERC20(loanERC20Denomination).approve(
            nftfiEscrowAddress,
            fullPayOffAmount
        );

        INFTEscrow(nftfiEscrowAddress).payBackLoan(loanId);

        paidDebt = fullPayOffAmount;
    }
}