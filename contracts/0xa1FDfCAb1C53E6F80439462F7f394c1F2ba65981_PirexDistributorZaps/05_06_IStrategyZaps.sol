// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IStrategyZaps {
    function claimFromVaultAsUnderlying(
        uint256 amount,
        uint256 assetIndex,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultAsFxs(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultAsEth(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address outputToken,
        address to
    ) external;

    function claimFromVaultAsUsdt(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultAsCvx(
        uint256 amount,
        uint256 minAmountOut,
        address to,
        bool lock
    ) external returns (uint256);

    function claimFromVaultAsCvx(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultAsCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultAsCvxCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);

    function claimFromVaultAndStakeIn3PoolConvex(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256);
}