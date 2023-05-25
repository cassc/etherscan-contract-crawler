// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

interface IDeFiPlaza {
  function swap(
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 minOutputAmount
  ) external payable returns (uint256 outputAmount);

  function addLiquidity(
    address inputToken,
    uint256 inputAmount,
    uint256 minLP
  ) external payable returns (uint256 deltaLP);

  function addMultiple(
    address[] calldata tokens,
    uint256[] calldata maxAmounts
  ) external payable returns (uint256 actualLP);

  function removeLiquidity(
    uint256 LPamount,
    address outputToken,
    uint256 minOutputAmount
  ) external returns (uint256 actualOutput);

  function removeMultiple(
    uint256 LPamount,
    address[] calldata tokens
  ) external returns (bool success);

  function bootstrapNewToken(
    address inputToken,
    uint256 maxInputAmount,
    address outputToken
  ) external returns (uint64 fractionBootstrapped);

  function bootstrapNewTokenWithBonus(
    address inputToken,
    uint256 maxInputAmount,
    address outputToken,
    address bonusToken
  ) external returns (uint256 bonusAmount);

  event Swapped(
    address sender,
    address inputToken,
    address outputToken,
    uint256 inputAmount,
    uint256 outputAmount
  );

  event LiquidityAdded(
    address sender,
    address token,
    uint256 tokenAmount,
    uint256 LPs
  );

  event MultiLiquidityAdded(
    address sender,
    uint256 LPs,
    uint256 totalLPafter
  );

  event LiquidityRemoved(
    address recipient,
    address token,
    uint256 tokenAmount,
    uint256 LPs
  );

  event MultiLiquidityRemoved(
    address sender,
    uint256 LPs,
    uint256 totalLPafter
  );

  event Bootstrapped(
    address sender,
    address inputToken,
    uint256 inputAmount,
    address outputToken,
    uint256 outputAmount
  );

  event BootstrapBonus(
    address sender,
    address bonusToken,
    uint256 bonusAmount
  );

  event BootstrapCompleted(
    address delistedToken,
    address listedToken
  );
}