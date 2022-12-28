// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

struct VaultParams {
    address quoteToken;
    address baseToken;
    address aggregatorAddr;
    address ubxnSwapRouter;
    address ubxnToken;
    address ubxnPairToken;
    address quotePriceFeed;
    address basePriceFeed;
    uint256 maxCap;
}

interface IVaultV2 {
    function estimatedPoolSize() external view returns (uint256);

    function estimatedDeposit(address account) external view returns (uint256);

    function depositQuote(uint256 amount) external;

    function depositBase(uint256 amount) external;

    function withdraw(uint256 shares) external;

    function withdrawQuote(uint256 shares) external;

    function vaultParams() external view returns (VaultParams memory);

    function position() external view returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}