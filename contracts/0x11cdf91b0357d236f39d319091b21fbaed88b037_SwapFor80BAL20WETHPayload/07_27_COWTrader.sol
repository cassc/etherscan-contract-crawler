// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IMilkman} from './interfaces/IMilkman.sol';

contract COWTrader {
  using SafeERC20 for IERC20;

  event TradeCanceled();
  event TradeRequested();

  error InvalidCaller();
  error NoPendingTrade();
  error PendingTrade();

  address public constant BAL80WETH20 = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant MILKMAN = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;
  address public constant PRICE_CHECKER = 0xBeA6AAC5bDCe0206A9f909d80a467C93A7D6Da7c;
  address public constant ALLOWED_CALLER = 0xA519a7cE7B24333055781133B13532AEabfAC81b;

  uint256 balBalance;
  uint256 wethBalance;
  bool trading;

  function trade() external {
    if (msg.sender != AaveGovernanceV2.SHORT_EXECUTOR) revert InvalidCaller();
    if (trading) revert PendingTrade();
    trading = true;

    balBalance = IERC20(AaveV2EthereumAssets.BAL_UNDERLYING).balanceOf(address(this));
    wethBalance = IERC20(AaveV2EthereumAssets.WETH_UNDERLYING).balanceOf(address(this));

    IERC20(AaveV2EthereumAssets.WETH_UNDERLYING).approve(MILKMAN, wethBalance);
    IERC20(AaveV2EthereumAssets.BAL_UNDERLYING).approve(MILKMAN, balBalance);

    IMilkman(MILKMAN).requestSwapExactTokensForTokens(
      wethBalance,
      IERC20(AaveV2EthereumAssets.WETH_UNDERLYING),
      IERC20(BAL80WETH20),
      address(AaveV2Ethereum.COLLECTOR),
      PRICE_CHECKER,
      abi.encode(150, bytes('')) // 1.5% slippage
    );

    IMilkman(MILKMAN).requestSwapExactTokensForTokens(
      balBalance,
      IERC20(AaveV2EthereumAssets.BAL_UNDERLYING),
      IERC20(BAL80WETH20),
      address(AaveV2Ethereum.COLLECTOR),
      PRICE_CHECKER,
      abi.encode(150, bytes('')) // 1.5% slippage
    );

    emit TradeRequested();
  }

  function cancelTrades(address wethMilkman, address balMilkman) external {
    if (!trading) revert NoPendingTrade();
    if (msg.sender != ALLOWED_CALLER && msg.sender != AaveGovernanceV2.SHORT_EXECUTOR)
      revert InvalidCaller();

    IMilkman(wethMilkman).cancelSwap(
      wethBalance,
      IERC20(AaveV2EthereumAssets.WETH_UNDERLYING),
      IERC20(BAL80WETH20),
      address(AaveV2Ethereum.COLLECTOR),
      PRICE_CHECKER,
      abi.encode(150, bytes('')) // 1.5% slippage
    );

    IMilkman(balMilkman).cancelSwap(
      balBalance,
      IERC20(AaveV2EthereumAssets.BAL_UNDERLYING),
      IERC20(BAL80WETH20),
      address(AaveV2Ethereum.COLLECTOR),
      PRICE_CHECKER,
      abi.encode(150, bytes('')) // 1.5% slippage
    );

    IERC20(AaveV2EthereumAssets.WETH_UNDERLYING).safeTransfer(
      address(AaveV2Ethereum.COLLECTOR),
      IERC20(AaveV2EthereumAssets.WETH_UNDERLYING).balanceOf(address(this))
    );
    IERC20(AaveV2EthereumAssets.BAL_UNDERLYING).safeTransfer(
      address(AaveV2Ethereum.COLLECTOR),
      IERC20(AaveV2EthereumAssets.BAL_UNDERLYING).balanceOf(address(this))
    );

    trading = false;

    emit TradeCanceled();
  }

  /// @notice Transfer any tokens accidentally sent to this contract to Aave V2 Collector
  /// @param tokens List of token addresses
  function rescueTokens(address[] calldata tokens) external {
    if (msg.sender != ALLOWED_CALLER && msg.sender != AaveGovernanceV2.SHORT_EXECUTOR)
      revert InvalidCaller();
    for (uint256 i = 0; i < tokens.length; ++i) {
      IERC20(tokens[i]).safeTransfer(
        address(AaveV2Ethereum.COLLECTOR),
        IERC20(tokens[i]).balanceOf(address(this))
      );
    }
  }
}