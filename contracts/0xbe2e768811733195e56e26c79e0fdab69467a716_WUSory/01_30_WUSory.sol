// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { INonfungiblePositionManager as INFPM } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IWUSD } from "./interfaces/IWUSD.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IFrontender } from "./interfaces/IFrontender.sol";

import { WUSer } from "./WUSer.sol";


contract WUSory is ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeToken for IERC20;


  INFPM private constant _NFPM = INFPM(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  ISwapRouter private constant _ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _WUSD = 0x068E3563b1c19590F822c0e13445c4FA1b9EEFa5;
  address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 private constant _FEE_RECHARGE = 10_000e6;
  uint256 private constant _FEE_CREATE = 25_000e6;
  uint256 private constant _FEE_BASE = 1_000e6;

  uint24 private constant _ROUTE = 1_0000;


  address[] private _wusers;

  mapping(address => address) private _wuser;
  mapping(address => bool) private _ineligible;


  event Create(address token, address wuser, uint256 dischargestamp);
  event Recharge(address token, uint256 dischargestamp);


  // wrap()'ables, WUSD, GLO, and WETH
  constructor (address[] memory ineligibles)
  {
    for (uint256 i; i < ineligibles.length; i++)
    {
      _ineligible[ineligibles[i]] = true;
    }


    IERC20(_USDT).safeApprove(address(_ROUTER), type(uint128).max);
  }


  function wusers () external view returns (address[] memory)
  {
    return _wusers;
  }

  function get (address token) external view returns (address)
  {
    return _wuser[token];
  }


  function create (address token, int24 tick, address referrer) external nonReentrant
  {
    require(token != address(0), "0 addr");
    require(!_ineligible[token], "!eligible");
    require(_wuser[token] == address(0), "created");


    (address token0, address token1) = _WUSD < token ? (_WUSD, token) : (token, _WUSD);


    _NFPM.createAndInitializePoolIfNecessary(token0, token1, _ROUTE, TickMath.getSqrtRatioAtTick(tick));

    IERC20(_USDT).safeTransferFrom(msg.sender, address(this), _FEE_CREATE.add(_FEE_BASE));
    IERC20(_USDC).safeTransferFrom(msg.sender, _REGISTRY.collector(), _FEE_BASE);
    IERC20(_USDT).safeTransfer(_REGISTRY.collector(), _FEE_BASE);


    _ROUTER.exactInputSingle(ISwapRouter.ExactInputSingleParams
    ({
      tokenIn: _USDT,
      tokenOut: _GLOVE,
      fee: _ROUTE,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: _FEE_CREATE,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    }));


    address wuser = address(new WUSer(token0, token1));


    _wusers.push(wuser);
    _wuser[token] = wuser;

    IGlove(_GLOVE).burn(address(this), IGlove(_GLOVE).balanceOf(address(this)).sub(1e18));

    AccessControl(_GLOVE).grantRole(0xbe74a168a238bf2df7daa27dd5487ac84cb89ae44fd7e7d1e4b6397bfe51dcb8, wuser);
    AccessControl(_REGISTRY.frontender()).grantRole(0xaef88082b8671e875d97d0d6c81d06fb9e76f97b3ad7523a55a378e5298aeeee, wuser);


    if (referrer != address(0))
    {
      IFrontender(_REGISTRY.frontender()).refer(msg.sender, 25_000e18, referrer);
    }


    emit Create(token, wuser, block.timestamp.add(30 days));
  }

  function recharge (address token, address referrer) external nonReentrant
  {
    address wuser = _wuser[token];

    require(wuser != address(0), "!created");
    require(block.timestamp > WUSer(wuser).dischargestamp().sub(2 days), "discharging");


    IERC20(_USDT).safeTransferFrom(msg.sender, address(this), _FEE_RECHARGE.add(_FEE_BASE));
    IERC20(_USDC).safeTransferFrom(msg.sender, _REGISTRY.collector(), _FEE_BASE);
    IERC20(_USDT).safeTransfer(_REGISTRY.collector(), _FEE_BASE);


    _ROUTER.exactInputSingle(ISwapRouter.ExactInputSingleParams
    ({
      tokenIn: _USDT,
      tokenOut: _GLOVE,
      fee: _ROUTE,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: _FEE_RECHARGE,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    }));


    IGlove(_GLOVE).burn(address(this), IGlove(_GLOVE).balanceOf(address(this)).sub(1e18));
    WUSer(wuser).recharge();


    if (referrer != address(0))
    {
      IFrontender(_REGISTRY.frontender()).refer(msg.sender, 10_000e18, referrer);
    }


    emit Recharge(token, block.timestamp.add(30 days));
  }
}