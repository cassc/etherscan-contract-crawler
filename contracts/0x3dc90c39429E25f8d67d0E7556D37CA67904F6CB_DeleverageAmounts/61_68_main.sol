//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers.sol";

contract InstaVaultResolver is Helpers {
    struct VaultInfo {
        address vaultAddr;
        address vaultDsa;
        uint256 revenue;
        uint256 revenueFee;
        VaultInterface.Ratios ratios;
        uint256 lastRevenueExchangePrice;
        uint256 exchangePrice;
        uint256 totalSupply;
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterface.BalVariables balances;
        uint256 netSupply;
        uint256 netBal;
    }

    function getVaultInfo() public view returns (VaultInfo memory vaultInfo_) {
        vaultInfo_.vaultAddr = address(vault);
        vaultInfo_.vaultDsa = vault.vaultDsa();
        vaultInfo_.revenue = vault.revenue();
        vaultInfo_.revenueFee = vault.revenueFee();
        vaultInfo_.ratios = vault.ratios();
        vaultInfo_.lastRevenueExchangePrice = vault.lastRevenueExchangePrice();
        (vaultInfo_.exchangePrice, ) = vault.getCurrentExchangePrice();
        vaultInfo_.totalSupply = vault.totalSupply();
        (
            vaultInfo_.netCollateral,
            vaultInfo_.netBorrow,
            vaultInfo_.balances,
            vaultInfo_.netSupply,
            vaultInfo_.netBal
        ) = vault.netAssets();
    }

    function getUserInfo(address user_)
        public
        view
        returns (
            VaultInfo memory vaultInfo_,
            uint256 vtokenBal_,
            uint256 amount_
        )
    {
        vaultInfo_ = getVaultInfo();
        vtokenBal_ = vault.balanceOf(user_);
        amount_ = (vtokenBal_ * vaultInfo_.exchangePrice) / 1e18;
    }

    struct RebalanceVariables {
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterface.BalVariables balances;
        uint256 netSupply;
        uint256 netBal;
        uint256 netBalUsed;
        uint256 netStEth;
        int256 netWeth;
        uint256 ratio;
        uint256 targetRatio;
        uint256 targetRatioDif;
        uint256[] deleverageAmts;
        uint256 hf;
        bool hfIsOk;
    }

    // This function gives data around leverage position
    function rebalanceOneData(address[] memory vaultsToCheck_)
        public
        view
        returns (
            uint256 finalCol_,
            uint256 finalDebt_,
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            address[] memory vaults_,
            uint256[] memory amts_,
            uint256 excessDebt_,
            uint256 paybackDebt_,
            uint256 totalAmountToSwap_,
            uint256 extraWithdraw_,
            bool isRisky_
        )
    {
        RebalanceVariables memory v_;
        (v_.netCollateral, v_.netBorrow, v_.balances, , v_.netBal) = vault
            .netAssets();
        if (v_.balances.wethVaultBal <= 1e14) v_.balances.wethVaultBal = 0;
        if (v_.balances.stethVaultBal <= 1e14) v_.balances.stethVaultBal = 0;
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        v_.netStEth =
            v_.netCollateral +
            v_.balances.stethVaultBal +
            v_.balances.stethDsaBal;
        v_.netWeth =
            int256(v_.balances.wethVaultBal + v_.balances.wethDsaBal) -
            int256(v_.netBorrow);
        v_.ratio = v_.netWeth < 0
            ? (uint256(-v_.netWeth) * 1e4) / v_.netStEth
            : 0;
            // 1% = 100
        v_.targetRatioDif = 10000 - (ratios_.minLimit - 10); // taking 0.1% more dif for margin
        if (v_.ratio < ratios_.minLimitGap) {
            // leverage till minLimit <> minLimitGap
            // final difference between collateral & debt in percent
            finalCol_ = (v_.netBal * 1e4) / v_.targetRatioDif;
            finalDebt_ = finalCol_ - v_.netBal;
            excessDebt_ = finalDebt_ - v_.netBorrow;
            flashTkn_ = wethAddr;
            flashAmt_ = (v_.netCollateral / 10) + ((excessDebt_ * 10) / 8); // 10% of current collateral + excessDebt / 0.8
            route_ = 5;
            totalAmountToSwap_ =
                excessDebt_ +
                v_.balances.wethVaultBal +
                v_.balances.wethDsaBal;
            v_.deleverageAmts = getMaxDeleverageAmts(vaultsToCheck_);
            (vaults_, amts_, totalAmountToSwap_) = getVaultsToUse(
                vaultsToCheck_,
                v_.deleverageAmts,
                totalAmountToSwap_
            );
            (, , , , , v_.hf) = IAaveLendingPool(
                aaveAddressProvider.getLendingPool()
            ).getUserAccountData(vault.vaultDsa());
            v_.hfIsOk = v_.hf > 1015 * 1e15;
            // only withdraw from aave position if position is safe
            if (v_.hfIsOk) {
                // keeping as non collateral for easier withdrawals
                extraWithdraw_ =
                    finalCol_ -
                    ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
            }
        } else {
            finalCol_ = v_.netStEth;
            finalDebt_ = uint256(-v_.netWeth);
            paybackDebt_ = v_.balances.wethVaultBal + v_.balances.wethDsaBal;
            (, , , , , v_.hf) = IAaveLendingPool(
                aaveAddressProvider.getLendingPool()
            ).getUserAccountData(vault.vaultDsa());
            v_.hfIsOk = v_.hf > 1015 * 1e15;
            // only withdraw from aave position if position is safe
            if (v_.ratio < (ratios_.maxLimit - 10) && v_.hfIsOk) {
                extraWithdraw_ =
                    finalCol_ -
                    ((finalDebt_ * 1e4) / (ratios_.maxLimit - 10));
            }
        }
        if (v_.ratio > ratios_.maxLimit) {
            isRisky_ = true;
        }

        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;
    }

    function rebalanceTwoData()
        public
        view
        returns (
            uint256 finalCol_,
            uint256 finalDebt_,
            uint256 withdrawAmt_, // always returned zero as of now
            address flashTkn_,
            uint256 flashAmt_,
            uint256 route_,
            uint256 saveAmt_,
            bool hfIsOk_
        )
    {
        RebalanceVariables memory v_;
        (, , , , , v_.hf) = IAaveLendingPool(
            aaveAddressProvider.getLendingPool()
        ).getUserAccountData(vault.vaultDsa());
        hfIsOk_ = v_.hf > 1015 * 1e15;
        (v_.netCollateral, v_.netBorrow, v_.balances, v_.netSupply,) = vault
            .netAssets();
        VaultInterface.Ratios memory ratios_ = vault.ratios();
        if (hfIsOk_) {
            v_.ratio = (v_.netBorrow * 1e4) / v_.netCollateral;
            v_.targetRatioDif = 10000 - (ratios_.maxLimit - 100); // taking 1% more dif for margin
            if (v_.ratio > ratios_.maxLimit) {
                v_.netBalUsed =
                    v_.netCollateral +
                    v_.balances.wethDsaBal -
                    v_.netBorrow;
                finalCol_ = (v_.netBalUsed * 1e4) / v_.targetRatioDif;
                finalDebt_ = finalCol_ - v_.netBalUsed;
                saveAmt_ = v_.netBorrow - finalDebt_ - v_.balances.wethDsaBal;
            }
        } else {
            v_.ratio = (v_.netBorrow * 1e4) / v_.netSupply;
            v_.targetRatio = (ratios_.minLimitGap + 10); // taking 0.1% more dif for margin
            v_.targetRatioDif = 10000 - v_.targetRatio;
            if (v_.ratio > ratios_.minLimit) {
                saveAmt_ =
                    ((1e4 * (v_.netBorrow - v_.balances.wethDsaBal)) -
                        (v_.targetRatio *
                            (v_.netSupply - v_.balances.wethDsaBal))) /
                    v_.targetRatioDif;
                finalCol_ = v_.netCollateral - saveAmt_;
                finalDebt_ = v_.netBorrow - saveAmt_ - v_.balances.wethDsaBal;
            }
        }
        flashTkn_ = wethAddr;
        flashAmt_ = (v_.netCollateral / 10) + ((saveAmt_ * 10) / 8); // 10% of current collateral + saveAmt_ / 0.8
        route_ = 5;
    }
}