// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import { IICHIVaultDepositGuard } from "./interfaces/IICHIVaultDepositGuard.sol";
import { IICHIVaultFactory } from "./interfaces/IICHIVaultFactory.sol";
import { IICHIVault } from "./interfaces/IICHIVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ICHIVaultDepositGuard is IICHIVaultDepositGuard, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    address public override ICHIVaultFactory;

    address constant NULL_ADDRESS = address(0);

    /// @notice Constructs the IICHIVaultDepositGuard contract.
    /// @param _ICHIVaultFactory The address of the ICHIVaultFactory.
    constructor(address _ICHIVaultFactory) {
        require(_ICHIVaultFactory != NULL_ADDRESS, "DG.constructor: zero address");
        ICHIVaultFactory = _ICHIVaultFactory;
        emit Deployed(_ICHIVaultFactory);
    }

    /// @notice Forwards a deposit to the specified ICHIVault after validating the input
    /// @dev Returns vault tokens to the msg.sender.
    /// @param vault The address of the ICHIVault to deposit into.
    /// @param vaultDeployer The address of the vault deployer's account.
    /// @param token The address of the token being deposited.
    /// @param amount The amount of the token being deposited.
    function forwardDepositToICHIVault(
        address vault,
        address vaultDeployer,
        address token,
        uint256 amount,
        uint256 minimumProceeds,
        address to
    ) external override nonReentrant returns (uint256 vaultTokens) {
        IICHIVault ichiVault = IICHIVault(vault);

        bytes32 factoryVaultKey = vaultKey(
            vaultDeployer,
            ichiVault.token0(),
            ichiVault.token1(),
            ichiVault.fee(),
            ichiVault.allowToken0(),
            ichiVault.allowToken1()
        );

        require(IICHIVaultFactory(ICHIVaultFactory).getICHIVault(factoryVaultKey) == vault, 
            "Invalid vault");

        require(
            token == ichiVault.token0() || token == ichiVault.token1(),
            "Invalid token"
        );

        if (token == ichiVault.token0()) {
            require(ichiVault.allowToken0(), 
            "Token0 deposits not allowed");
        } else {
            require(ichiVault.allowToken1(), 
            "Token1 deposits not allowed");
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeIncreaseAllowance(vault, amount);


        uint256 token0Amount = token == ichiVault.token0() ? amount : 0;
        uint256 token1Amount = token == ichiVault.token1() ? amount : 0;

        vaultTokens = ichiVault.deposit(token0Amount, token1Amount, to);
        require(vaultTokens >= minimumProceeds, "Slippage too great. Try again.");

        emit DepositForwarded(msg.sender, vault, token, amount, vaultTokens, to);
    }

    /// @notice Computes the vault key based on input parameters.
    /// @param vaultDeployer The address of the vault deployer's account.
    /// @param token0 The address of the first token.
    /// @param token1 The address of the second token.
    /// @param fee The fee for the vault.
    /// @param allowToken0 A boolean indicating whether token0 is allowed.
    /// @param allowToken1 A boolean indicating whether token1 is allowed.
    /// @return key The computed vault key.
    function vaultKey(
        address vaultDeployer,
        address token0,
        address token1,
        uint24 fee,
        bool allowToken0,
        bool allowToken1
    ) public view override returns (bytes32 key) {
        key = IICHIVaultFactory(ICHIVaultFactory).genKey(
            vaultDeployer, 
            token0, 
            token1, 
            fee, 
            allowToken0, 
            allowToken1);
    }

}