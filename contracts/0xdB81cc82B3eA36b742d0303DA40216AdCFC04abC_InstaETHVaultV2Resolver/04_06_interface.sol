// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface VaultV2Interface {
    function decimals() external view returns (uint8);

    function asset() external view returns (address);

    // From ERC20Upgradable
    function balanceOf(address account) external view returns (uint256);

    // iTokenV2 current exchange price.
    function exchangePrice() external view returns (uint256);

    function revenueExchangePrice() external view returns (uint256);

    function aggrMaxVaultRatio() external view returns (uint256);

    function withdrawFeeAbsoluteMin() external view returns (uint256);

    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsInStETH aaveV2;
        ProtocolAssetsInWstETH aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH euler;
        ProtocolAssetsInStETH morphoAaveV2;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    function getNetAssets()
        external
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_,
            NetAssetsHelper memory assets_
        );

    function maxRiskRatio(
        uint8 protocolId
    ) external view returns (uint256 maxRiskRatio);

    function vaultDSA() external view returns (address);

    function revenueFeePercentage() external view returns (uint256);

    function withdrawalFeePercentage() external view returns (uint256);

    function leverageMaxUnitAmountLimit() external view returns (uint256);

    function revenue() external view returns (uint256);

    // iTokenV2 total supply.
    function totalSupply() external view returns (uint256);

    function getRatioAaveV2()
        external
        view
        returns (uint256 stEthAmount, uint256 ethAmount, uint256 ratio);

    function getRatioAaveV3(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioCompoundV3(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioEuler(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioMorphoAaveV2()
        external
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        );
}

interface IAaveV2AddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IWsteth {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface IAaveV2DataProvider {
    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256, // liquidityRate (IN RAY) (100% => 1e29)
            uint256, // variableBorrowRate (IN RAY) (100% => 1e29)
            uint256,
            uint256,
            uint256,
            uint256,
            uint40
        );
}

interface IAaveV3DataProvider {
    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface IComet {
    // The current protocol utilization percentage as a decimal, represented by an unsigned integer, scaled up by 10 ^ 18. E.g. 1e17 or 100000000000000000 is 10% utilization.
    function getUtilization() external view returns (uint);

    // The per second supply rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
    function getSupplyRate(uint utilization) external view returns (uint64);

    // The per second borrow rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
    function getBorrowRate(uint utilization) external view returns (uint64);
}

interface IEulerSimpleView {
    // underlying -> interest rate
    function interestRates(
        address underlying
    ) external view returns (uint borrowSPY, uint borrowAPY, uint supplyAPY);
}

interface IMorphoAaveLens {
    function getRatesPerYear(
        address _poolToken
    )
        external
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        );
}

interface ILiteVaultV1 {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IChainlink {
    function latestAnswer() external view returns (int256 answer);
}