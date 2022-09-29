// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { IFarming } from "./interfaces/IFarming.sol";
import { IPancakeFactory } from "./interfaces/IPancakeFactory.sol";
import { IPancakeRouter02 } from "./interfaces/IPancakeRouter02.sol";

uint256 constant N_COINS = 2;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface IStableSwap {
  function add_liquidity(uint256[N_COINS] memory amounts, uint256 min_mint_amount) external;

  function token() external returns (IERC20Upgradeable);
}

struct SwapInfo {
  IERC20Upgradeable token0;
  IERC20Upgradeable token1;
  IERC20Upgradeable lp;
  uint256 pid;
}

contract CurveProxyForDeposit is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event StableSwapInfoChanged(address indexed stableSwap, SwapInfo swapInfo);

  IFarming public farming;

  mapping(IStableSwap => SwapInfo) public supportedPids;

  function initialize(IFarming _farming) public initializer {
    __Ownable_init();
    farming = _farming;
  }

  function depositToFarming(
    IStableSwap stableSwap,
    uint256 amount0,
    uint256 amount1,
    uint256 minMintAmount
  ) external {
    SwapInfo memory swapInfo = supportedPids[stableSwap];
    swapInfo.token0.safeTransferFrom(msg.sender, address(this), amount0);
    swapInfo.token1.safeTransferFrom(msg.sender, address(this), amount1);
    uint256[N_COINS] memory amounts = [amount0, amount1];
    stableSwap.add_liquidity(amounts, minMintAmount);
    farming.deposit(swapInfo.pid, swapInfo.lp.balanceOf(address(this)), false, msg.sender);
    uint256 tokenABal = swapInfo.token0.balanceOf(address(this));
    uint256 tokenBBal = swapInfo.token1.balanceOf(address(this));
    if (tokenABal > 0) {
      swapInfo.token0.safeTransfer(msg.sender, tokenABal);
    }
    if (tokenBBal > 0) {
      swapInfo.token1.safeTransfer(msg.sender, tokenBBal);
    }
  }

  function addSupportedTokens(
    IStableSwap stableSwap,
    IERC20Upgradeable token0,
    IERC20Upgradeable token1,
    uint256 pid
  ) external onlyOwner {
    IERC20Upgradeable lp = stableSwap.token();
    IERC20Upgradeable(token0).approve(address(stableSwap), type(uint256).max);
    IERC20Upgradeable(token1).approve(address(stableSwap), type(uint256).max);
    lp.approve(address(farming), type(uint256).max);
    supportedPids[stableSwap] = SwapInfo({ token0: token0, token1: token1, lp: lp, pid: pid });
    emit StableSwapInfoChanged(address(stableSwap), supportedPids[stableSwap]);
  }
}