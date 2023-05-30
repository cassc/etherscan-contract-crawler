// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title 治理操作接口定义
interface IGovernanceActions {
    /// @notice Change governance
    /// @dev This function can only be called by governance
    /// @param account 新的governance地址
    function setGovernance(address account) external;

    /// @notice Set the token to be verified for all fund, vice versa
    /// @dev This function can only be called by governance
    /// @param token 目标代币
    /// @param isVerified 是否受信任
    function setVerifiedToken(address token, bool isVerified) external;

    /// @notice Set the swap path for harvest
    /// @dev This function can only be called by governance
    /// @param token 目标代币
    /// @param path 路径
    function setHarvestPath(address token, bytes calldata path) external;

    /// @notice 设置swap时最大滑点，取值范围为 0-1e4, 计算公式为：MaxSwapSlippage = (1 - (sqrtSlippage/1e4)^2) * 100%
    ///         如设置最大滑点 0.5%, 则 sqrtSlippage 应设置为9974，此时 MaxSwapSlippage = (1-(9974/1e4)^2)*100% = 0.5% 
    /// @dev This function can only be called by governance
    /// @param sqrtSlippage 0-1e4
    function setMaxSqrtSlippage(uint32 sqrtSlippage) external;

    /// @notice Set the max price impact for swap
    /// @dev This function can only be called by governance
    /// @param priceImpact 0-1e4
    function setMaxPriceImpact(uint32 priceImpact) external;
}