//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";

contract Helpers {
    IAaveAddressProvider internal constant AAVE_ADDR_PROVIDER =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IAaveDataprovider internal constant AAVE_DATA =
        IAaveDataprovider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    InstaDeleverageAndWithdrawWrapper
        internal constant deleverageAndWithdrawWrapper =
        InstaDeleverageAndWithdrawWrapper(
            0xA6978cBA39f86491Ae5dcA53f4cdeFCB100E3E3d
        );
    IChainlink internal constant stethInEth =
        IChainlink(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);
    IChainlink internal constant ethInUsd =
        IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    address internal constant ETH_ADDR =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant STETH_ADDR =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant ETH_VAULT_ADDR =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    struct HelperStruct {
        uint256 stethCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 tokenCollateralAmt;
    }

    /**
     * @dev Helper function
     * @notice Helper function for calculating amounts
     */
    function getAmounts(
        address vaultAddr_,
        uint256 decimals_,
        uint256 tokenPriceInBaseCurrency_,
        uint256 ethPriceInBaseCurrency_,
        uint256 stEthLimit_,
        uint256 maxLimitThreshold_
    )
        internal
        view
        returns (
            uint256 stethCollateralAmt,
            uint256 wethDebtAmt,
            uint256 availableWithdraw
        )
    {
        VaultInterfaceToken tokenVault_ = VaultInterfaceToken(vaultAddr_);
        HelperStruct memory helper_;

        (
            helper_.tokenCollateralAmt,
            stethCollateralAmt,
            wethDebtAmt,
            helper_.tokenVaultBal,
            helper_.tokenDSABal,
            helper_.netTokenBal
        ) = tokenVault_.getVaultBalances();

        uint256 tokenPriceInEth = (tokenPriceInBaseCurrency_ * 1e18) /
            ethPriceInBaseCurrency_;
        uint256 tokenColInEth_ = (helper_.tokenCollateralAmt *
            tokenPriceInEth) / (10**decimals_);
        uint256 ethCoveringDebt_ = (stethCollateralAmt * stEthLimit_) / 10000;
        uint256 excessDebt_ = (ethCoveringDebt_ < wethDebtAmt)
            ? wethDebtAmt - ethCoveringDebt_
            : 0;
        uint256 currentRatioMax = tokenColInEth_ == 0
            ? 0
            : (excessDebt_ * 10000) / tokenColInEth_;
        if (currentRatioMax < maxLimitThreshold_) {
            availableWithdraw =
                helper_.tokenVaultBal +
                helper_.tokenDSABal +
                (((maxLimitThreshold_ - currentRatioMax) *
                    helper_.tokenCollateralAmt) / maxLimitThreshold_);
        }
    }

    struct CurrentRatioVars {
        uint256 netCollateral;
        uint256 netBorrow;
        uint256 netSupply;
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenColAmt;
        uint256 stethColAmt;
        uint256 wethDebt;
        uint256 netTokenBal;
        uint256 ethCoveringDebt;
        uint256 excessDebt;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 excessDebtInBaseCurrency;
        uint256 netTokenColInBaseCurrency;
        uint256 netTokenSupplyInBaseCurrency;
    }

    function getCurrentRatios(address vaultAddr_)
        public
        view
        returns (uint256 currentRatioMax_, uint256 currentRatioMin_)
    {
        CurrentRatioVars memory v_;
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            (
                v_.netCollateral,
                v_.netBorrow,
                ,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();
            currentRatioMax_ = (v_.netBorrow * 1e4) / v_.netCollateral;
            currentRatioMin_ = (v_.netBorrow * 1e4) / v_.netSupply;
        } else {
            VaultInterfaceToken vault_ = VaultInterfaceToken(vaultAddr_);
            v_.tokenAddr = vault_.token();
            v_.tokenDecimals = VaultInterfaceCommon(vaultAddr_).decimals();
            (
                v_.tokenColAmt,
                v_.stethColAmt,
                v_.wethDebt,
                ,
                ,
                v_.netTokenBal
            ) = vault_.getVaultBalances();
            VaultInterfaceToken.Ratios memory ratios_ = vault_.ratios();
            v_.ethCoveringDebt = (v_.stethColAmt * ratios_.stEthLimit) / 10000;
            v_.excessDebt = v_.ethCoveringDebt < v_.wethDebt
                ? v_.wethDebt - v_.ethCoveringDebt
                : 0;
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            v_.excessDebtInBaseCurrency =
                (v_.excessDebt * v_.ethPriceInBaseCurrency) /
                1e18;

            v_.netTokenColInBaseCurrency =
                (v_.tokenColAmt * v_.tokenPriceInBaseCurrency) /
                (10**v_.tokenDecimals);
            v_.netTokenSupplyInBaseCurrency =
                (v_.netTokenBal * v_.tokenPriceInBaseCurrency) /
                (10**v_.tokenDecimals);

            currentRatioMax_ =
                (v_.excessDebtInBaseCurrency * 10000) /
                v_.netTokenColInBaseCurrency;
            currentRatioMin_ =
                (v_.excessDebtInBaseCurrency * 10000) /
                v_.netTokenSupplyInBaseCurrency;
        }
    }
}