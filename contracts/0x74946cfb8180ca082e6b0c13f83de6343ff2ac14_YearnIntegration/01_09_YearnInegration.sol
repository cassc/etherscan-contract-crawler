// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "./base/CoinStatsBaseV1.sol";
import "../integrationInterface/IntegrationInterface.sol";

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

interface IYVault {
  function deposit(uint256) external;

  function deposit(uint256, address) external;

  function withdraw(uint256) external;

  function getPricePerFullShare() external view returns (uint256);

  function token() external view returns (address);

  function decimals() external view returns (uint256);

  // V2
  function pricePerShare() external view returns (uint256);
}

interface IYVaultV1Registry {
  function getVaults() external view returns (address[] memory);

  function getVaultsLength() external view returns (uint256);
}

interface ICurveRegistry {
  function getSwapAddress(address tokenAddress)
    external
    view
    returns (address poolAddress);

  function getNumTokens(address poolAddress)
    external
    view
    returns (uint8 numTokens);
}

contract YearnIntegration is IntegrationInterface, CoinStatsBaseV1 {
  using SafeERC20 for IERC20;

  ICurveRegistry public curveRegistry;

  // solhint-disable-next-line var-name-mixedcase
  IYVaultV1Registry public V1Registry =
    IYVaultV1Registry(0x3eE41C098f9666ed2eA246f4D2558010e59d63A0);

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  event Deposit(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );

  event Withdraw(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );

  constructor(
    ICurveRegistry _curveRegistry,
    address curveIntegration,
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
    // Curve Registry
    curveRegistry = _curveRegistry;

    // Curve
    approvedTargets[curveIntegration] = true;

    // 0x exchange
    approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    // 1inch exchange
    approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
  }

  /**
    @notice Returns pools total supply
    @param vaultAddress Yearn pool address from which to get supply
   */
  function getTotalSupply(address vaultAddress) public view returns (uint256) {
    return IERC20(vaultAddress).totalSupply();
  }

  /**
    @notice Returns account balance from pool
    @param vaultAddress  Yearn pool address from which to get balance
    @param account The account
   */
  function getBalance(address vaultAddress, address account)
    public
    view
    override
    returns (uint256 balance)
  {
    return IERC20(vaultAddress).balanceOf(account);
  }

  /**
    @notice Adds liquidity to any Yearn vaults with ETH or ERC20 tokens
    @param entryTokenAddress The token used for entry (address(0) if ETH).
    @param entryTokenAmount The depositTokenAmount of entryTokenAddress to invest
    @param vaultAddress Yearn vault address
    @param depositTokenAddress Token to be transfered to poolAddress
    @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
    @param underlyingTarget Underlying target which will execute swap
    @param targetDepositTokenAddress Token which will be used to deposit fund in target contract
    @param swapTarget Underlying target's swap target
    @param swapData Data for swap
    @param affiliate Affiliate address 
  */
  function deposit(
    address entryTokenAddress,
    uint256 entryTokenAmount,
    address vaultAddress,
    address depositTokenAddress,
    uint256 minExitTokenAmount,
    address underlyingTarget,
    address targetDepositTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    // Transfer {entryTokens} to contract
    entryTokenAmount = _pullTokens(entryTokenAddress, entryTokenAmount);

    // Subtract goodwill
    entryTokenAmount -= _subtractGoodwill(
      entryTokenAddress,
      entryTokenAmount,
      affiliate,
      true
    );

    if (entryTokenAddress == address(0)) {
      entryTokenAddress = ETH_ADDRESS;
    }

    // Swap {entryToken} to {depositToken}
    // Should return depositToken
    uint256 depositTokenAmount;

    if (underlyingTarget == address(0)) {
      depositTokenAmount = _fillQuote(
        entryTokenAddress,
        entryTokenAmount,
        depositTokenAddress,
        swapTarget,
        swapData
      );
    } else {
      uint256 value;
      if (entryTokenAddress == ETH_ADDRESS) {
        value = entryTokenAmount;
      } else {
        _approveToken(entryTokenAddress, underlyingTarget, entryTokenAmount);
      }

      address poolAddress = curveRegistry.getSwapAddress(depositTokenAddress);

      // solhint-disable-next-line avoid-low-level-calls
      bytes memory callData = abi.encodeWithSignature(
        "deposit(address,uint256,address,address,uint256,address,address,address,bytes,address)",
        entryTokenAddress,
        entryTokenAmount,
        poolAddress,
        targetDepositTokenAddress,
        0,
        address(0),
        address(0),
        swapTarget,
        swapData,
        affiliate
      );

      depositTokenAmount = _fillCurveDepositQuote(
        depositTokenAddress,
        underlyingTarget,
        value,
        callData
      );
    }

    uint256 tokensReceived = _makeDeposit(
      depositTokenAddress,
      depositTokenAmount,
      vaultAddress,
      minExitTokenAmount
    );

    emit Deposit(msg.sender, vaultAddress, tokensReceived, affiliate);
  }

  function _makeDeposit(
    address depositTokenAddress,
    uint256 depositTokenAmount,
    address vaultAddress,
    uint256 minExitTokenAmount
  ) internal returns (uint256 tokensReceived) {
    // Deposit to Vault

    _approveToken(depositTokenAddress, vaultAddress);

    uint256 iniYVaultBal = IERC20(vaultAddress).balanceOf(msg.sender);
    IYVault(vaultAddress).deposit(depositTokenAmount, msg.sender);
    tokensReceived = IERC20(vaultAddress).balanceOf(msg.sender) - iniYVaultBal;

    require(
      tokensReceived >= minExitTokenAmount,
      "VaultDeposit: High Slippage"
    );
  }

  /**
    @notice Removes liquidity from Yarn vaults in ETH or ERC20 tokens
    @param vaultAddress Yearn vault address
    @param vaultTokenAmount Token amount to be transferes to integration contract
    @param exitTokenAddress Specifies the token which will be send to caller
    @param minExitTokenAmount Min acceptable amount of tokens to reeive
    @param underlyingTarget Underlying target which will execute swap
    @param targetWithdrawTokenAddress Token which will be used to withdraw funds in target contract
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address to share fees
  */
  function withdraw(
    address vaultAddress,
    uint256 vaultTokenAmount,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address underlyingTarget,
    address targetWithdrawTokenAddress,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    // Transfer {liquidityTokens} to contract
    vaultTokenAmount = _pullTokens(vaultAddress, vaultTokenAmount);

    // Get underlying token from vault
    address underlyingToken = IYVault(vaultAddress).token();
    uint256 underlyingTokenReceived = _vaultWithdraw(
      vaultAddress,
      vaultTokenAmount,
      underlyingToken
    );

    // Swap to {exitTokenAddress}
    uint256 exitTokenAmount;
    if (underlyingTarget == address(0)) {
      exitTokenAmount = _fillQuote(
        underlyingToken,
        underlyingTokenReceived,
        exitTokenAddress,
        swapTarget,
        swapData
      );
    } else {
      _approveToken(underlyingToken, underlyingTarget);

      address poolAddress = curveRegistry.getSwapAddress(underlyingToken);
      // solhint-disable-next-line avoid-low-level-calls
      bytes memory callData = abi.encodeWithSignature(
        "withdraw(address,uint256,address,uint256,address,address,address,bytes,address)",
        poolAddress,
        underlyingTokenReceived,
        exitTokenAddress,
        0,
        address(0),
        targetWithdrawTokenAddress,
        swapTarget,
        swapData,
        affiliate
      );

      exitTokenAmount = _fillCurveWithdrawQuote(
        exitTokenAddress,
        underlyingTarget,
        callData
      );
    }
    require(exitTokenAmount >= minExitTokenAmount, "Withdraw: High Slippage");

    exitTokenAmount -= _subtractGoodwill(
      exitTokenAddress,
      exitTokenAmount,
      affiliate,
      true
    );

    // Transfer tokens to caller
    if (exitTokenAddress == ETH_ADDRESS) {
      Address.sendValue(payable(msg.sender), exitTokenAmount);
    } else {
      IERC20(exitTokenAddress).safeTransfer(msg.sender, exitTokenAmount);
    }

    emit Withdraw(msg.sender, vaultAddress, exitTokenAmount, affiliate);
  }

  function _vaultWithdraw(
    address poolAddress,
    uint256 entryTokenAmount,
    address underlyingToken
  ) internal returns (uint256 underlyingReceived) {
    uint256 iniUnderlyingBal = _getBalance(underlyingToken);

    IYVault(poolAddress).withdraw(entryTokenAmount);

    underlyingReceived = _getBalance(underlyingToken) - iniUnderlyingBal;
  }

  function _fillQuote(
    address inputTokenAddress,
    uint256 inputTokenAmount,
    address outputTokenAddress,
    address swapTarget,
    bytes memory swapData
  ) internal returns (uint256 outputTokensBought) {
    if (inputTokenAddress == outputTokenAddress) {
      return inputTokenAmount;
    }

    if (swapTarget == WETH) {
      if (
        outputTokenAddress == address(0) || outputTokenAddress == ETH_ADDRESS
      ) {
        IWETH(WETH).withdraw(inputTokenAmount);
        return inputTokenAmount;
      } else {
        IWETH(WETH).deposit{value: inputTokenAmount}();
        return inputTokenAmount;
      }
    }

    uint256 value;
    if (inputTokenAddress == ETH_ADDRESS) {
      value = inputTokenAmount;
    } else {
      _approveToken(inputTokenAddress, swapTarget);
    }

    uint256 initialOutputTokenBalance = _getBalance(outputTokenAddress);

    // solhint-disable-next-line reason-string
    require(approvedTargets[swapTarget], "FillQuote: Target is not approved");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = swapTarget.call{value: value}(swapData);
    require(success, "FillQuote: Failed to swap tokens");

    outputTokensBought =
      _getBalance(outputTokenAddress) -
      initialOutputTokenBalance;

    // solhint-disable-next-line reason-string
    require(outputTokensBought > 0, "FillQuote: Swapped to invalid token");
  }

  function _fillCurveDepositQuote(
    address exitTokenAddress,
    address underlyingTarget,
    uint256 value,
    bytes memory callData
  ) internal returns (uint256 outputTokensBought) {
    uint256 initialOutputTokenBalance = _getBalance(exitTokenAddress);

    // solhint-disable-next-line reason-string
    require(
      approvedTargets[underlyingTarget],
      "FillQuote: Target is not approved"
    );

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = underlyingTarget.call{value: value}(callData);
    require(success, "FillQuote: Failed to swap tokens");

    outputTokensBought =
      _getBalance(exitTokenAddress) -
      initialOutputTokenBalance;

    // solhint-disable-next-line reason-string
    require(outputTokensBought > 0, "FillQuote: Swapped to invalid token");
  }

  function _fillCurveWithdrawQuote(
    address exitTokenAddress,
    address underlyingTarget,
    bytes memory callData
  ) internal returns (uint256 outputTokensBought) {
    uint256 initialOutputTokenBalance = _getBalance(exitTokenAddress);

    // solhint-disable-next-line reason-string
    require(
      approvedTargets[underlyingTarget],
      "FillQuote: Target is not approved"
    );

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = underlyingTarget.call(callData);

    require(success, "FillQuote: Failed to swap tokens");

    outputTokensBought =
      _getBalance(exitTokenAddress) -
      initialOutputTokenBalance;

    // solhint-disable-next-line reason-string
    require(outputTokensBought > 0, "FillQuote: Swapped to invalid token");
  }

  /**
    @notice Utility function to determine the quantity of underlying tokens removed from vault
    @param poolAddress Yearn vault from which to remove liquidity
    @param liquidity Quantity of vault tokens to remove
    @return Quantity of underlying LP or token removed
  */
  function removeAssetReturn(
    address poolAddress,
    address,
    uint256 liquidity
  ) external view override returns (uint256) {
    require(liquidity > 0, "RAR: Zero amount return");

    IYVault vault = IYVault(poolAddress);

    address[] memory v1Vaults = V1Registry.getVaults();

    for (uint256 i = 0; i < V1Registry.getVaultsLength(); i++) {
      if (v1Vaults[i] == poolAddress)
        return (liquidity * (vault.getPricePerFullShare())) / (1e18);
    }
    return (liquidity * (vault.pricePerShare())) / (10**vault.decimals());
  }
}