// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerVenus {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function getAllMarkets() external view returns (address[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
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
}

interface IDistributionVenus {
    function claimVenus(address holder, address[] memory vTokens) external;
}

interface IOracleVenus {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}