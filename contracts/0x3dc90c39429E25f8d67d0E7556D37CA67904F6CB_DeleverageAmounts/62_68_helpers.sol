//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Helpers {
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant stEthAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function checkIfBorrowAllowed(address vaultDsaAddr_, uint256 wethBorrowAmt_) internal view returns (bool) {
        (,, uint256 availableBorrowsETH,,,) = IAaveLendingPool(aaveAddressProvider.getLendingPool()).getUserAccountData(vaultDsaAddr_);
        return wethBorrowAmt_ < availableBorrowsETH;
    }

    function getMaxDeleverageAmt(address vaultAddr_)
        internal
        view
        returns (uint256 amount_)
    {
        VaultInterface vault_ = VaultInterface(vaultAddr_);
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
        VaultInterface.Ratios memory ratios_ = vault_.ratios();
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

    function getMaxDeleverageAmts(address[] memory vaults_)
        internal
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            amounts_[i] = getMaxDeleverageAmt(vaults_[i]);
        }
    }

    function bubbleSort(address[] memory vaults_, uint256[] memory amounts_)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < amounts_.length - 1; i++) {
            for (uint256 j = 0; j < amounts_.length - i - 1; j++) {
                if (amounts_[j] < amounts_[j + 1]) {
                    (
                        vaults_[j],
                        vaults_[j + 1],
                        amounts_[j],
                        amounts_[j + 1]
                    ) = (
                        vaults_[j + 1],
                        vaults_[j],
                        amounts_[j + 1],
                        amounts_[j]
                    );
                }
            }
        }
        return (vaults_, amounts_);
    }

    function getTrimmedArrays(
        address[] memory vaults_,
        uint256[] memory amounts_,
        uint256 length_
    )
        internal
        pure
        returns (address[] memory finalVaults_, uint256[] memory finalAmts_)
    {
        finalVaults_ = new address[](length_);
        finalAmts_ = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            finalVaults_[i] = vaults_[i];
            finalAmts_[i] = amounts_[i];
        }
    }

    function getVaultsToUse(
        address[] memory vaultsToCheck_,
        uint256[] memory deleverageAmts_,
        uint256 leverageAmt_
    )
        internal
        pure
        returns (
            address[] memory vaults_,
            uint256[] memory amounts_,
            uint256 swapAmt_
        )
    {
        (vaults_, amounts_) = bubbleSort(vaultsToCheck_, deleverageAmts_);
        swapAmt_ = leverageAmt_;
        uint256 i;
        while (swapAmt_ > 0 && i < vaults_.length && amounts_[i] > 0) {
            if (amounts_[i] > swapAmt_) amounts_[i] = swapAmt_;
            swapAmt_ -= amounts_[i];
            i++;
        }
        if (i != vaults_.length)
            (vaults_, amounts_) = getTrimmedArrays(vaults_, amounts_, i);
    }
}