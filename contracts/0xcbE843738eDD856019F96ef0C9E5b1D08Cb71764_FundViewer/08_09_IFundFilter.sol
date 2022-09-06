// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct FundFilterInitializeParams {
    address priceOracle;
    address swapRouter;
    address positionManager;
    address positionViewer;
    address protocolAdapter;
    address[] allowedUnderlyingTokens;
    address[] allowedTokens;
    address[] allowedProtocols;
    uint256 minManagementFee;
    uint256 maxManagementFee;
    uint256 minCarriedInterest;
    uint256 maxCarriedInterest;
    address daoAddress;
    uint256 daoProfit;
}

interface IFundFilter {

    event AllowedUnderlyingTokenUpdated(address indexed token, bool allowed);

    event AllowedTokenUpdated(address indexed token, bool allowed);

    event AllowedProtocolUpdated(address indexed protocol, bool allowed);

    function priceOracle() external view returns (address);

    function swapRouter() external view returns (address);

    function positionManager() external view returns (address);

    function positionViewer() external view returns (address);

    function protocolAdapter() external view returns (address);

    function allowedUnderlyingTokens() external view returns (address[] memory);

    function isUnderlyingTokenAllowed(address token) external view returns (bool);

    function allowedTokens() external view returns (address[] memory);

    function isTokenAllowed(address token) external view returns (bool);

    function allowedProtocols() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function minManagementFee() external view returns (uint256);

    function maxManagementFee() external view returns (uint256);

    function minCarriedInterest() external view returns (uint256);

    function maxCarriedInterest() external view returns (uint256);

    function daoAddress() external view returns (address);

    function daoProfit() external view returns (uint256);

}