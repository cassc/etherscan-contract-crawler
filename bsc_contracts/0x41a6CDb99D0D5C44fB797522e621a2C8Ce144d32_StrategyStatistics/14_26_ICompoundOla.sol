// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerOla {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

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

    function getAllMarkets() external view returns (address[] memory);

    function getUnderlyingPriceInLen(address underlying)
        external
        view
        returns (uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

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
}