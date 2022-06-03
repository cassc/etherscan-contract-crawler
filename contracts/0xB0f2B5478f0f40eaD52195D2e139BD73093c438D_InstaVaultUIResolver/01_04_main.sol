//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface.sol";
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InstaVaultUIResolver is Helpers {
    struct CommonVaultInfo {
        address token;
        uint8 decimals;
        uint256 userBalance;
        uint256 userBalanceStETH;
        uint256 aaveTokenSupplyRate;
        uint256 aaveWETHBorrowRate_;
        uint256 totalStEthBal;
        uint256 wethDebtAmt;
        uint256 userSupplyAmount;
        uint256 vaultTVLInAsset;
        uint256 availableWithdraw;
        uint256 withdrawalFee;
        uint256 revenueFee;
        VaultInterfaceToken.Ratios ratios;
    }

    /**
     * @dev Get all the info
     * @notice Get info of all the vaults and the user
     */
    function getInfoCommon(address user_, address[] memory vaults_)
        public
        view
        returns (CommonVaultInfo[] memory commonInfo_)
    {
        uint256 len_ = vaults_.length;
        commonInfo_ = new CommonVaultInfo[](vaults_.length);

        for (uint256 i = 0; i < len_; i++) {
            VaultInterfaceCommon vault_ = VaultInterfaceCommon(vaults_[i]);
            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            uint256 ethPriceInBaseCurrency_ = aaveOracle_.getAssetPrice(
                WETH_ADDR
            );

            if (vaults_[i] == ETH_VAULT_ADDR) {
                HelperStruct memory helper_;
                VaultInterfaceETH ethVault_ = VaultInterfaceETH(vaults_[i]);
                VaultInterfaceETH.Ratios memory ratios_ = ethVault_.ratios();

                commonInfo_[i].token = ETH_ADDR;
                commonInfo_[i].decimals = 18;
                commonInfo_[i].userBalance = user_.balance;
                commonInfo_[i].userBalanceStETH = TokenInterface(STETH_ADDR)
                    .balanceOf(user_);
                commonInfo_[i].aaveTokenSupplyRate = 0;

                VaultInterfaceETH.BalVariables memory balances_;
                (
                    helper_.stethCollateralAmt,
                    commonInfo_[i].wethDebtAmt,
                    balances_,
                    ,

                ) = ethVault_.netAssets();

                commonInfo_[i].totalStEthBal =
                    helper_.stethCollateralAmt +
                    balances_.stethDsaBal +
                    balances_.stethVaultBal;
                commonInfo_[i].availableWithdraw = balances_.totalBal;
                uint256 currentRatioMax_ = (commonInfo_[i].wethDebtAmt * 1e4) /
                    helper_.stethCollateralAmt;
                uint256 maxLimitThreshold = ratios_.maxLimit - 20; // taking 0.2% margin
                if (currentRatioMax_ < maxLimitThreshold) {
                    commonInfo_[i].availableWithdraw +=
                        helper_.stethCollateralAmt -
                        ((1e4 * commonInfo_[i].wethDebtAmt) /
                            maxLimitThreshold);
                }
                commonInfo_[i].ratios.maxLimit = ratios_.maxLimit;
                commonInfo_[i].ratios.minLimit = ratios_.minLimit;
                commonInfo_[i].ratios.minLimitGap = ratios_.minLimitGap;
                commonInfo_[i].ratios.maxBorrowRate = ratios_.maxBorrowRate;
            } else {
                VaultInterfaceToken tokenVault_ = VaultInterfaceToken(
                    vaults_[i]
                );
                commonInfo_[i].ratios = tokenVault_.ratios();

                commonInfo_[i].token = tokenVault_.token();
                commonInfo_[i].decimals = vault_.decimals();
                commonInfo_[i].userBalance = TokenInterface(
                    commonInfo_[i].token
                ).balanceOf(user_);
                commonInfo_[i].userBalanceStETH = 0;
                (
                    ,
                    ,
                    ,
                    commonInfo_[i].aaveTokenSupplyRate,
                    ,
                    ,
                    ,
                    ,
                    ,

                ) = AAVE_DATA.getReserveData(commonInfo_[i].token);

                uint256 maxLimitThreshold = (commonInfo_[i].ratios.maxLimit -
                    100) - 10; // taking 0.1% margin from withdrawLimit
                uint256 stethCollateralAmt_;

                (
                    stethCollateralAmt_,
                    commonInfo_[i].wethDebtAmt,
                    commonInfo_[i].availableWithdraw
                ) = getAmounts(
                    vaults_[i],
                    commonInfo_[i].decimals,
                    aaveOracle_.getAssetPrice(commonInfo_[i].token),
                    ethPriceInBaseCurrency_,
                    commonInfo_[i].ratios.stEthLimit,
                    maxLimitThreshold
                );

                commonInfo_[i].totalStEthBal =
                    stethCollateralAmt_ +
                    IERC20(STETH_ADDR).balanceOf(vault_.vaultDsa()) +
                    IERC20(STETH_ADDR).balanceOf(vaults_[i]);
            }

            (uint256 exchangePrice, ) = vault_.getCurrentExchangePrice();
            commonInfo_[i].userSupplyAmount =
                (vault_.balanceOf(user_) * exchangePrice) /
                1e18;

            (, , , , commonInfo_[i].aaveWETHBorrowRate_, , , , , ) = AAVE_DATA
                .getReserveData(WETH_ADDR);

            commonInfo_[i].vaultTVLInAsset =
                (vault_.totalSupply() * exchangePrice) /
                1e18;
            commonInfo_[i].withdrawalFee = vault_.withdrawalFee();
            commonInfo_[i].revenueFee = vault_.revenueFee();
        }
    }

    struct DeleverageAndWithdrawVars {
        uint256 netCollateral;
        uint256 netBorrow;
        VaultInterfaceETH.BalVariables balances;
        uint256 netSupply;
        uint256 availableWithdraw;
        uint256 maxLimitThreshold;
        uint256 withdrawLimitThreshold;
        address tokenAddr;
        uint256 tokenCollateralAmt;
        uint256 tokenVaultBal;
        uint256 tokenDSABal;
        uint256 netTokenBal;
        uint256 idealTokenBal;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenColInEth;
        uint256 tokenSupplyInEth;
        uint256 withdrawAmtInEth;
        uint256 idealTokenBalInEth;
    }

    struct DeleverageAndWithdrawReturnVars {
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 premium;
        uint256 premiumEth;
        uint256 tokenPriceInEth;
        uint256 exchangePrice;
        uint256 itokenAmt;
        uint256 withdrawalFee;
        uint256 currentRatioMin;
        uint256 currentRatioMax;
        uint256 deleverageAmtMax;
        uint256 deleverageAmtMin;
        uint256 deleverageAmtTillMinLimit;
        uint256 deleverageAmtTillMaxLimit;
    }

    function getDeleverageAndWithdrawData(
        address vaultAddr_,
        uint256 withdrawAmt_
    ) public view returns (DeleverageAndWithdrawReturnVars memory r_) {
        DeleverageAndWithdrawVars memory v_;
        r_.premium = deleverageAndWithdrawWrapper.premium();
        r_.premiumEth = deleverageAndWithdrawWrapper.premiumEth();
        r_.withdrawalFee = VaultInterfaceCommon(vaultAddr_).withdrawalFee();
        (r_.exchangePrice, ) = VaultInterfaceCommon(vaultAddr_)
            .getCurrentExchangePrice();
        r_.itokenAmt = (withdrawAmt_ * 1e18) / r_.exchangePrice;
        withdrawAmt_ = withdrawAmt_ - (withdrawAmt_ * r_.withdrawalFee) / 1e4;
        (r_.currentRatioMax, r_.currentRatioMin) = getCurrentRatios(vaultAddr_);
        r_.tokenDecimals = VaultInterfaceCommon(vaultAddr_).decimals();
        if (vaultAddr_ == ETH_VAULT_ADDR) {
            r_.tokenAddr = ETH_ADDR;
            r_.tokenPriceInEth = 1e18;
            VaultInterfaceETH.Ratios memory ratios_ = VaultInterfaceETH(
                vaultAddr_
            ).ratios();
            (
                v_.netCollateral,
                v_.netBorrow,
                v_.balances,
                v_.netSupply,

            ) = VaultInterfaceETH(vaultAddr_).netAssets();

            v_.availableWithdraw = v_.balances.totalBal;
            v_.maxLimitThreshold = ratios_.maxLimit - 20; // taking 0.2% margin
            if (r_.currentRatioMax < v_.maxLimitThreshold) {
                v_.availableWithdraw +=
                    v_.netCollateral -
                    ((1e4 * v_.netBorrow) / v_.maxLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will remain the same
            if (withdrawAmt_ > v_.balances.totalBal) {
                r_.deleverageAmtMax =
                    (v_.netBorrow * (withdrawAmt_ - v_.balances.totalBal)) /
                    (v_.netCollateral - v_.netBorrow);
            } else r_.deleverageAmtMax = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            r_.deleverageAmtMin =
                (v_.netBorrow * withdrawAmt_) /
                (v_.netSupply - v_.netBorrow);

            // using this deleverageAmt_ the max ratio will be taken to withdrawLimit (unless ideal balance is sufficient)
            if (v_.availableWithdraw <= withdrawAmt_) {
                uint256 withdrawLimit_ = ratios_.maxLimit - 20; // taking 0.2% margin from maxLimit
                r_.deleverageAmtTillMaxLimit =
                    ((v_.netBorrow * 1e4) -
                        (withdrawLimit_ * (v_.netSupply - withdrawAmt_))) /
                    (1e4 - withdrawLimit_);
            } else r_.deleverageAmtTillMaxLimit = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                r_.deleverageAmtTillMinLimit =
                    ((v_.netBorrow * 1e4) -
                        (ratios_.minLimit * (v_.netSupply - withdrawAmt_))) /
                    (1e4 - ratios_.minLimit);
            } else r_.deleverageAmtTillMinLimit = 0;
        } else {
            r_.tokenAddr = VaultInterfaceToken(vaultAddr_).token();
            VaultInterfaceToken.Ratios memory ratios_ = VaultInterfaceToken(
                vaultAddr_
            ).ratios();
            (
                v_.tokenCollateralAmt,
                ,
                ,
                v_.tokenVaultBal,
                v_.tokenDSABal,
                v_.netTokenBal
            ) = VaultInterfaceToken(vaultAddr_).getVaultBalances();
            v_.idealTokenBal = v_.tokenVaultBal + v_.tokenDSABal;

            IAavePriceOracle aaveOracle_ = IAavePriceOracle(
                AAVE_ADDR_PROVIDER.getPriceOracle()
            );
            v_.tokenPriceInBaseCurrency = aaveOracle_.getAssetPrice(
                r_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle_.getAssetPrice(WETH_ADDR);
            r_.tokenPriceInEth =
                (v_.tokenPriceInBaseCurrency * 1e18) /
                v_.ethPriceInBaseCurrency;
            v_.tokenColInEth =
                (v_.tokenCollateralAmt * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);
            v_.tokenSupplyInEth =
                (v_.netTokenBal * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);
            v_.withdrawAmtInEth =
                (withdrawAmt_ * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);
            v_.idealTokenBalInEth =
                (v_.idealTokenBal * r_.tokenPriceInEth) /
                (10**r_.tokenDecimals);

            // using this deleverageAmt_ the max ratio will remain the same
            if (v_.withdrawAmtInEth > v_.idealTokenBalInEth) {
                r_.deleverageAmtMax =
                    (r_.currentRatioMax *
                        (v_.withdrawAmtInEth - v_.idealTokenBalInEth)) /
                    (10000 - ratios_.stEthLimit);
            } else r_.deleverageAmtMax = 0;

            // using this deleverageAmt_ the min ratio will remain the same
            r_.deleverageAmtMin =
                (r_.currentRatioMin * v_.withdrawAmtInEth) /
                (10000 - ratios_.stEthLimit);

            v_.availableWithdraw = v_.tokenVaultBal + v_.tokenDSABal;
            uint256 withdrawLimit_ = ratios_.maxLimit - 100;
            v_.withdrawLimitThreshold = withdrawLimit_ - 10; // keeping 0.1% margin
            if (r_.currentRatioMax < v_.withdrawLimitThreshold) {
                v_.availableWithdraw += (((v_.withdrawLimitThreshold -
                    r_.currentRatioMax) * v_.tokenCollateralAmt) /
                    v_.withdrawLimitThreshold);
            }

            // using this deleverageAmt_ the max ratio will be taken to withdrawLimit (unless ideal balance is sufficient)
            if (v_.availableWithdraw <= withdrawAmt_) {
                r_.deleverageAmtTillMaxLimit =
                    ((r_.currentRatioMax * v_.tokenColInEth) -
                        (v_.withdrawLimitThreshold *
                            (v_.tokenColInEth -
                                (v_.withdrawAmtInEth -
                                    v_.idealTokenBalInEth)))) /
                    (10000 - ratios_.stEthLimit);
            } else r_.deleverageAmtTillMaxLimit = 0;

            // using this deleverageAmt_ the min ratio will be taken to minLimit
            if (v_.availableWithdraw <= withdrawAmt_) {
                r_.deleverageAmtTillMinLimit =
                    ((r_.currentRatioMin * v_.tokenSupplyInEth) -
                        (ratios_.minLimit *
                            (v_.tokenSupplyInEth - v_.withdrawAmtInEth))) /
                    (10000 - ratios_.stEthLimit);
            } else r_.deleverageAmtTillMinLimit = 0;
        }
    }

    function getITokenInfo(address itokenAddr_, address priceResolverAddr_)
        public
        view
        returns (
            address tokenAddr_,
            uint256 tokenDecimals_,
            uint256 mintFee_,
            uint256 redeemFee_,
            uint256 streamingFee_,
            uint256 swapFee_,
            uint256 deleverageFee_,
            uint256 totalSupply_,
            uint256 itokenPriceInEth_,
            uint256 itokenPriceInUsd_,
            uint256 itokenPriceInUnderlyingToken_,
            uint256 volume_
        )
    {
        VaultInterfaceCommon vault_ = VaultInterfaceCommon(itokenAddr_);
        if (itokenAddr_ == ETH_VAULT_ADDR) tokenAddr_ = ETH_ADDR;
        else tokenAddr_ = VaultInterfaceToken(itokenAddr_).token();
        tokenDecimals_ = vault_.decimals();
        mintFee_ = 0;
        redeemFee_ = vault_.withdrawalFee();
        streamingFee_ = 0;
        swapFee_ = vault_.swapFee();
        deleverageFee_ = vault_.deleverageFee();
        totalSupply_ = vault_.totalSupply();
        (itokenPriceInUnderlyingToken_, ) = vault_.getCurrentExchangePrice();
        itokenPriceInEth_ = IPriceResolver(priceResolverAddr_).getPriceInEth();
        itokenPriceInUsd_ = IPriceResolver(priceResolverAddr_).getPriceInUsd();
        volume_ = 0;
    }
}