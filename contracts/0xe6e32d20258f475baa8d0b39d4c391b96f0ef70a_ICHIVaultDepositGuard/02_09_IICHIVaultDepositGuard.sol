// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IICHIVaultDepositGuard {

    event Deployed(address _ICHIVaultFactory);
    
    event DepositForwarded(
        address indexed sender,
        address indexed vault,
        address indexed token,
        uint256 amount,
        uint256 shares,
        address to
    );

    function ICHIVaultFactory() external view returns (address);

    function forwardDepositToICHIVault(
        address vault,
        address vaultDeployer,
        address token,
        uint256 amount,
        uint256 minimumProceeds,
        address to
    ) external returns (uint256 vaultTokens);

    function vaultKey(
        address vaultDeployer,
        address token0,
        address token1,
        uint24 fee,
        bool allowToken0,
        bool allowToken1
    ) external view returns (bytes32 key);
}