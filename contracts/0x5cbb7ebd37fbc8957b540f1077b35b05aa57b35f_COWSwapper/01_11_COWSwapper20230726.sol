// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IMilkman} from './interfaces/IMilkman.sol';

contract COWSwapper {
  using SafeERC20 for IERC20;

  error InvalidCaller();

  address public constant ALLOWED_CALLER = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
  address public constant MILKMAN = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;
  address public constant CHAINLINK_PRICE_CHECKER = 0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c;

  uint256 usdtBalance;
  uint256 daiBalance;

  function swap() external {
    if (msg.sender != AaveGovernanceV2.SHORT_EXECUTOR) revert InvalidCaller();

    usdtBalance = IERC20(AaveV2EthereumAssets.USDT_UNDERLYING).balanceOf(address(this));
    daiBalance = IERC20(AaveV2EthereumAssets.DAI_UNDERLYING).balanceOf(address(this));

    IERC20(AaveV2EthereumAssets.USDT_UNDERLYING).safeApprove(MILKMAN, usdtBalance);
    IERC20(AaveV2EthereumAssets.DAI_UNDERLYING).safeApprove(MILKMAN, daiBalance);

    IMilkman(MILKMAN).requestSwapExactTokensForTokens(
      usdtBalance,
      IERC20(AaveV2EthereumAssets.USDT_UNDERLYING),
      IERC20(AaveV2EthereumAssets.USDC_UNDERLYING),
      address(this),
      CHAINLINK_PRICE_CHECKER,
      _getEncodedData(AaveV2EthereumAssets.USDT_ORACLE, AaveV2EthereumAssets.USDC_ORACLE)
    );

    IMilkman(MILKMAN).requestSwapExactTokensForTokens(
      daiBalance,
      IERC20(AaveV2EthereumAssets.DAI_UNDERLYING),
      IERC20(AaveV2EthereumAssets.USDC_UNDERLYING),
      address(this),
      CHAINLINK_PRICE_CHECKER,
      _getEncodedData(AaveV2EthereumAssets.DAI_ORACLE, AaveV2EthereumAssets.USDC_ORACLE)
    );
  }

  function cancelUsdt(address milkman) external {
    if (msg.sender != ALLOWED_CALLER && msg.sender != AaveGovernanceV2.SHORT_EXECUTOR) {
      revert InvalidCaller();
    }

    IMilkman(milkman).cancelSwap(
      usdtBalance,
      IERC20(AaveV2EthereumAssets.USDT_UNDERLYING),
      IERC20(AaveV2EthereumAssets.USDC_UNDERLYING),
      address(this),
      CHAINLINK_PRICE_CHECKER,
      _getEncodedData(AaveV2EthereumAssets.USDT_ORACLE, AaveV2EthereumAssets.USDC_ORACLE)
    );

    IERC20(AaveV2EthereumAssets.USDT_UNDERLYING).safeTransfer(
      address(AaveV2Ethereum.COLLECTOR),
      IERC20(AaveV2EthereumAssets.USDT_UNDERLYING).balanceOf(address(this))
    );
  }

  function cancelDai(address milkman) external {
    if (msg.sender != ALLOWED_CALLER && msg.sender != AaveGovernanceV2.SHORT_EXECUTOR) {
      revert InvalidCaller();
    }

    IMilkman(milkman).cancelSwap(
      daiBalance,
      IERC20(AaveV2EthereumAssets.DAI_UNDERLYING),
      IERC20(AaveV2EthereumAssets.USDC_UNDERLYING),
      address(this),
      CHAINLINK_PRICE_CHECKER,
      _getEncodedData(AaveV2EthereumAssets.DAI_ORACLE, AaveV2EthereumAssets.USDC_ORACLE)
    );

    IERC20(AaveV2EthereumAssets.DAI_UNDERLYING).safeTransfer(
      address(AaveV2Ethereum.COLLECTOR),
      IERC20(AaveV2EthereumAssets.DAI_UNDERLYING).balanceOf(address(this))
    );
  }

  function depositIntoAaveV2(address token) external {
    uint256 amount = IERC20(token).balanceOf(address(this));
    IERC20(token).safeApprove(address(AaveV2Ethereum.POOL), amount);
    AaveV2Ethereum.POOL.deposit(token, amount, address(AaveV2Ethereum.COLLECTOR), 0);
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

  function _getEncodedData(
    address oracleOne,
    address oracleTwo
  ) internal pure returns (bytes memory) {
    bytes memory data;
    address[] memory paths = new address[](2);
    paths[0] = oracleOne;
    paths[1] = oracleTwo;

    bool[] memory reverses = new bool[](2);
    reverses[1] = true;

    data = abi.encode(paths, reverses);

    return abi.encode(100, data); // 100 = 1% slippage
  }
}