// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Vault.sol";
import "./interfaces/IUniV3Adapter.sol";

/// @title Saffron Fixed Income Uniswap V3 Vault
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Vault implementation that supports Uniswap V3 adapters
contract UniV3Vault is Vault, IUniV3Vault {
  using SafeERC20 for IERC20;

  /// @notice token0 earnings
  uint256 public earnings0;

  /// @notice token1 earnings
  uint256 public earnings1;

  /// @inheritdoc IVault
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapter,
    uint256 _fixedSideCapacity,
    uint256 _variableSideCapacity,
    address _variableAsset,
    uint256 _feeBps,
    address _feeReceiver
  ) public override(Vault, IVault) notInitialized {
    require(msg.sender == factory, "NF");
    super.initialize(_vaultId, _duration, _adapter, _fixedSideCapacity, _variableSideCapacity, _variableAsset, _feeBps, _feeReceiver);
  }

  /// @notice Deposit assets into the vault
  /// @param amount Amount of asset to deposit
  /// @param side ID of side to deposit into
  /// @param deployCapitalData Data passed to adapter's deployCapital(), ultimately used to call Uniswap V3's PositionManager#mint()
  function deposit(
    uint256 amount,
    uint256 side,
    bytes calldata deployCapitalData
  ) public override isInitialized nonReentrant {
    require(!isStarted, "DAS");
    require(side == FIXED || side == VARIABLE, "IS");

    if (side == VARIABLE) {
      // Variable side deposits

      require(deployCapitalData.length == 0, "OEI");

      // Deposit only up to capacity
      amount = (amount + variableBearerToken.totalSupply() >= variableSideCapacity)
        ? variableSideCapacity - variableBearerToken.totalSupply()
        : amount;
      require(amount > 0, "NZD");

      // Transfer (restricted to non-deflationary tokens)
      uint256 oldBalance = IERC20(variableAsset).balanceOf(address(this));
      IERC20(variableAsset).safeTransferFrom(address(msg.sender), address(this), amount);
      uint256 newBalance = IERC20(variableAsset).balanceOf(address(this));
      require(amount == newBalance - oldBalance, "NDT");

      // Mint bearer tokens
      variableBearerToken.mint(address(msg.sender), amount);

      uint256[] memory amounts = new uint256[](1);
      amounts[0] = amount;
      emit FundsDeposited(amounts, side, msg.sender);
    } else {
      // Fixed Side deposits

      require(deployCapitalData.length > 0, "NEI");
      require(amount == 0, "OZD");
      require(claimToken.totalSupply() == 0, "CTM");

      // Add liquidity to Uniswap V3 and mint claim token
      (uint256 amount0, uint256 amount1) = IUniV3Adapter(address(adapter)).deployCapital(msg.sender, deployCapitalData);
      claimToken.mint(address(msg.sender), 1);

      uint256[] memory amounts = new uint256[](2);
      amounts[0] = amount0;
      amounts[1] = amount1;
      emit FundsDeposited(amounts, side, msg.sender);
    }

    // Start the vault if we're at capacity
    if (claimToken.totalSupply() == 1 && variableBearerToken.totalSupply() == variableSideCapacity) {
      start();
    }
  }

  /// @notice Withdraw assets from the vault
  /// @param side ID of side to withdraw from
  /// @param removeLiquidityData Data that is ultimately used to call Uniswap V3's PositionManager#decreaseLiquidity()
  function withdraw(uint256 side, bytes calldata removeLiquidityData) public override isInitialized nonReentrant {
    require(side == FIXED || side == VARIABLE, "IS");

    IUniV3Adapter uniV3Adapter = IUniV3Adapter(address(adapter));

    if (!isStarted && side == FIXED) {
      // Early withdrawal - Fixed side

      require(removeLiquidityData.length > 0, "NEI");

      // Burn claim token and return liquidity back to depositor
      uint256 amount = claimToken.balanceOf(address(msg.sender));
      require(amount > 0, "NCT");
      claimToken.burn(address(msg.sender), amount);
      (uint256 amount0, uint256 amount1) = uniV3Adapter.earlyReturnCapital(msg.sender, side, removeLiquidityData);

      logFundsWithdrawn(FIXED, amount0, amount1, true);
      return;
    }

    if (!isStarted && side == VARIABLE) {
      // Early withdrawal - Variable side

      require(removeLiquidityData.length == 0, "OEI");

      // Burn bearer tokens and return assets back to depositor
      uint256 amount = variableBearerToken.balanceOf(address(msg.sender));
      variableBearerToken.burn(address(msg.sender), amount);
      IERC20(variableAsset).safeTransfer(address(msg.sender), amount);

      logFundsWithdrawn(VARIABLE, amount, true);
      return;
    }

    require(isStarted && block.timestamp > endTime, "WBE");

    uint256 amount0;
    uint256 amount1;

    if (side == FIXED) {
      // Normal withdrawal - Fixed side

      require(removeLiquidityData.length > 0, "NEI");

      uint256 bearerBalance = fixedBearerToken.balanceOf(msg.sender);
      require(bearerBalance > 0, "NFS");

      // Settle earnings if they haven't been settled yet and mint bearer tokens to the feeReceiver
      if (!earningsSettled) {
        (earnings0, earnings1) = uniV3Adapter.settleEarnings();
        earningsSettled = true;
        applyFee();
        emit VaultEnded(block.timestamp, msg.sender);
      }

      // Burn bearer token and return liquidity back to depositor
      (amount0, amount1) = uniV3Adapter.removeLiquidity(msg.sender, removeLiquidityData);
      uniV3Adapter.returnCapital(msg.sender, amount0, amount1, side);
      fixedBearerToken.burn(address(msg.sender), bearerBalance);

      logFundsWithdrawn(FIXED, amount0, amount1, false);
      return;
    }

    if (side == VARIABLE) {
      // Normal withdrawal - Variable side

      require(removeLiquidityData.length == 0, "OEI");

      // Caller must be a variable side depositor or feeReceiver
      uint256 bearerBalance = variableBearerToken.balanceOf(address(msg.sender));
      require(bearerBalance > 0 || (msg.sender == feeReceiver && variableBearerToken.totalSupply() != 0), "NVS");

      // Settle earnings if they haven't been settled yet and mint bearer tokens to the feeReceiver
      if (!earningsSettled) {
        (earnings0, earnings1) = uniV3Adapter.settleEarnings();
        earningsSettled = true;
        applyFee();
        // Recalculate bearer balance if called by feeReceiver
        if (msg.sender == feeReceiver) {
          bearerBalance = variableBearerToken.balanceOf(address(msg.sender));
        }
        emit VaultEnded(block.timestamp, msg.sender);
      }

      // Return proportional share of Uniswap V3 fees to caller
      amount0 = FullMath.mulDiv(FullMath.mulDiv(bearerBalance, 1e18, variableBearerToken.totalSupply()), earnings0, 1e18);
      amount1 = FullMath.mulDiv(FullMath.mulDiv(bearerBalance, 1e18, variableBearerToken.totalSupply()), earnings1, 1e18);
      earnings0 -= amount0;
      earnings1 -= amount1;
      uniV3Adapter.returnCapital(msg.sender, amount0, amount1, side);
      variableBearerToken.burn(address(msg.sender), bearerBalance);

      logFundsWithdrawn(VARIABLE, amount0, amount1, false);
      return;
    }
  }

  /// @dev Helper function for logging an array with length 1
  function logFundsWithdrawn(uint256 side, uint256 amount0, bool isEarly) internal {
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount0;
    emit FundsWithdrawn(amounts, side, msg.sender, isEarly);
  }

  /// @dev Helper function for logging an array with length 2
  function logFundsWithdrawn(uint256 side, uint256 amount0, uint256 amount1, bool isEarly) internal {
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = amount0;
    amounts[1] = amount1;
    emit FundsWithdrawn(amounts, side, msg.sender, isEarly);
  }
}