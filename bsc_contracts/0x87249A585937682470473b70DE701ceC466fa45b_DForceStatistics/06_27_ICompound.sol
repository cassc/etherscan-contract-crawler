// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerCompound {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function getAllMarkets() external view returns (address[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IInterestRateModel {
    function blocksPerYear() external view returns (uint256);
}

interface IComptrollerOla is IComptrollerCompound {
    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getUnderlyingPriceInLen(address underlying)
        external
        view
        returns (uint256);

    function rainMaker() external view returns (address);
}

interface IDistributionOla {
    function claimComp(address holder, address[] calldata cTokens) external;

    function compAccrued(address holder) external view returns (uint256);

    function compInitialIndex() external view returns (uint224);

    function compSupplyState(address xToken)
        external
        view
        returns (uint224, uint32);

    function compSupplierIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function compBorrowState(address xToken)
        external
        view
        returns (uint224, uint32);

    function compBorrowerIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function lnIncentiveTokenAddress() external view returns (address);

    function compSpeeds(address _asset) external view returns (uint256);

    function compSupplySpeeds(address _asset) external view returns (uint256);
}

interface IComptrollerVenus is IComptrollerCompound {
    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function oracle() external view returns (address);

    function venusInitialIndex() external view returns (uint224);

    function venusAccrued(address account) external view returns (uint256);

    function venusSupplyState(address xToken)
        external
        view
        returns (uint224, uint32);

    function venusSupplierIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function venusBorrowState(address xToken)
        external
        view
        returns (uint224, uint32);

    function venusBorrowerIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function getXVSAddress() external view returns (address);

    function getXVSVTokenAddress() external view returns (address);

    function venusSpeeds(address _asset) external view returns (uint256);

    function venusSupplySpeeds(address _asset) external view returns (uint256);
}

interface IDistributionVenus {
    function claimVenus(address holder, address[] memory vTokens) external;
}

interface IOracleVenus {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}