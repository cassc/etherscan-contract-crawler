//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
    function getPriceOracle() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IAaveDataprovider {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint40
        );
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface VaultInterfaceETH {
    struct BalVariables {
        uint256 wethVaultBal;
        uint256 wethDsaBal;
        uint256 stethVaultBal;
        uint256 stethDsaBal;
        uint256 totalBal;
    }

    function netAssets()
        external
        view
        returns (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            uint256 netSupply_,
            uint256 netBal_
        );

    struct Ratios {
        uint16 maxLimit;
        uint16 minLimit;
        uint16 minLimitGap;
        uint128 maxBorrowRate;
    }

    function ratios() external view returns (Ratios memory);
}

interface VaultInterfaceToken {
    struct Ratios {
        uint16 maxLimit;
        uint16 maxLimitGap;
        uint16 minLimit;
        uint16 minLimitGap;
        uint16 stEthLimit;
        uint128 maxBorrowRate;
    }

    function ratios() external view returns (Ratios memory);

    function token() external view returns (address);

    function idealExcessAmt() external view returns (uint256);

    function getVaultBalances()
        external
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        );
}

interface VaultInterfaceCommon {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function vaultDsa() external view returns (address);

    function totalSupply() external view returns (uint256);

    function revenueFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function deleverageFee() external view returns (uint256);
}

interface InstaDeleverageAndWithdrawWrapper {
    function premium() external view returns (uint256);

    function premiumEth() external view returns (uint256);
}

interface IPriceResolver {
    function getPriceInUsd() external view returns (uint256 priceInUSD);

    function getPriceInEth() external view returns (uint256 priceInETH);
}

interface IChainlink {
    function latestAnswer() external view returns (int256 answer);
}