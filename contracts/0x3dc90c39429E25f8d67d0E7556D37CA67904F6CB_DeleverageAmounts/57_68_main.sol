//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./variables.sol";

contract DeleverageAmounts is Variables {
    function getMaxDeleverageAmt(address vaultAddr_)
        public
        view
        returns (uint256 amount_)
    {
        if (vaultAddr_ == address(vault)) {
            VaultInterface.Ratios memory ratio_ = vault.ratios();
            (, uint netBorrow_, , uint netSupply_,) = vault.netAssets();
            // 1e4 + 10
            uint minLimitGap_ = ratio_.minLimitGap + 10; // 0.1% margin
            amount_ = ((netBorrow_ * 1e4) - (minLimitGap_ * netSupply_)) / (1e4 - minLimitGap_);
        } else {
            Vault2Interface vault_ = Vault2Interface(vaultAddr_);
            address tokenAddr_ = vault_.token();
            uint256 tokenDecimals_ = vault_.decimals();
            (
                ,
                uint256 stethCollateral_,
                uint256 wethDebt_,
                ,
                ,
                uint256 netTokenBal_
            ) = vault_.getVaultBalances();
            Vault2Interface.Ratios memory ratios_ = vault_.ratios();
            uint256 ethCoveringDebt_ = (stethCollateral_ * ratios_.stEthLimit) /
                10000;
            uint256 excessDebt_ = ethCoveringDebt_ < wethDebt_
                ? wethDebt_ - ethCoveringDebt_
                : 0;
            uint256 tokenPriceInEth_ = IAavePriceOracle(
                aaveAddressProvider.getPriceOracle()
            ).getAssetPrice(tokenAddr_);
            uint256 netTokenSupplyInEth_ = (netTokenBal_ * tokenPriceInEth_) /
                (10**tokenDecimals_);
            uint256 currentRatioMin_ = netTokenSupplyInEth_ == 0
                ? 0
                : (excessDebt_ * 10000) / netTokenSupplyInEth_;
            if (currentRatioMin_ > ratios_.minLimit) {
                // keeping 0.1% margin for final ratio
                amount_ =
                    ((currentRatioMin_ - (ratios_.minLimitGap + 10)) *
                        netTokenSupplyInEth_) /
                    (10000 - ratios_.stEthLimit);
            }
        }
    }

    function getMaxDeleverageAmts(address[] memory vaults_)
        public
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            amounts_[i] = getMaxDeleverageAmt(vaults_[i]);
        }
    }
}