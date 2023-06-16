// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { INonfungiblePositionManager as INFPM } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { EnumerableSet } from "./utils/EnumerableSet.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IWUSD } from "./interfaces/IWUSD.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IFrontender } from "./interfaces/IFrontender.sol";


contract WUSer is IERC721Receiver, ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeToken for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;


  INFPM private constant _NFPM = INFPM(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _WUSD = 0x068E3563b1c19590F822c0e13445c4FA1b9EEFa5;
  address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  uint24 private constant _ROUTE = 1_0000;

  int24 private constant _MIN_TICK = -887200;
  int24 private constant _MAX_TICK = 887200;


  struct Returnance
  {
    bool creditized;
    uint256 amount0;
    uint256 amount1;
  }

  struct Provision
  {
    uint128 liquidity;
    uint48 timestamp;
    uint48 withdrawable;
  }


  address private immutable _WUSory;
  address private immutable _TOKEN_0;
  address private immutable _TOKEN_1;


  uint256 private _dischargestamp;

  EnumerableSet.UintSet private _nfts;

  mapping(address => bool) private _provided;
  mapping(address => uint256) private _nftOf;
  mapping(uint256 => Provision) private _provision;


  event Provide(address indexed account, uint256 nft, uint256 amount, address referrer);
  event Increase(address indexed account, uint256 nft, uint256 amount);
  event Decrease(address indexed account, uint256 nft);
  event Collect(address indexed account, uint256 nft, uint256 amount);
  event Withdraw(address indexed account, uint256 nft);


  constructor (address token0, address token1)
  {
    _TOKEN_0 = token0;
    _TOKEN_1 = token1;

    _WUSory = msg.sender;

    _dischargestamp = block.timestamp.add(30 days);


    IERC20(token0).safeApprove(address(_NFPM), type(uint128).max);
    IERC20(token1).safeApprove(address(_NFPM), type(uint128).max);
  }

  function onERC721Received (address, address, uint256, bytes calldata) external view override returns (bytes4)
  {
    require(msg.sender == address(_NFPM), "!NFPM");


    return 0x150b7a02;
  }


  function dischargestamp () external view returns (uint256)
  {
    return _dischargestamp;
  }

  function tokens () external view returns (address, address)
  {
    return (_TOKEN_0, _TOKEN_1);
  }


  function nfts () external view returns (uint256[] memory)
  {
    return _nfts.values();
  }

  function nftOf (address account) external view returns (uint256)
  {
    return _nftOf[account];
  }

  function provisionOf (uint256 nft) external view returns (Provision memory)
  {
    return _provision[nft];
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return amount.mul(percent).div(100_00);
  }


  function _wusd (uint256 amount0, uint256 amount1) internal view returns (uint256)
  {
    return _TOKEN_0 == _WUSD ? amount0 : amount1;
  }


  function _fee (uint256 amount) internal pure returns (uint256)
  {
    return Math.max(100e6, _percent(amount, 1_00).mul(1e6).div(1e18));
  }

  function _return (Returnance memory returnance, uint256 nft) internal
  {
    if (returnance.amount0 > 0)
    {
      IERC20(_TOKEN_0).safeTransfer(msg.sender, returnance.amount0);
    }

    if (returnance.amount1 > 0)
    {
      IERC20(_TOKEN_1).safeTransfer(msg.sender, returnance.amount1);
    }


    uint256 amount = _wusd(returnance.amount0, returnance.amount1);

    if (amount > 0)
    {
      if (returnance.creditized && block.timestamp < _dischargestamp)
      {
        uint256 multiplier = Math.min((amount * 100_00).div(100_000e18), 100_00);
        uint256 credits = _percent(IGlove(_GLOVE).creditlessOf(msg.sender), Math.min(_percent(100, multiplier.mul(block.timestamp.sub(_provision[nft].timestamp).div(1 weeks))), 100_00));


        IGlove(_GLOVE).creditize(msg.sender, credits);


        _provision[nft].timestamp = uint48(block.timestamp);
      }
    }
  }

  function provide (uint256 addable0, uint256 addable1, address referrer) external nonReentrant
  {
    require(!_provided[msg.sender], "provided");


    IERC20(_TOKEN_0).safeTransferFrom(msg.sender, address(this), addable0);
    IERC20(_TOKEN_1).safeTransferFrom(msg.sender, address(this), addable1);


    (uint256 nft, uint128 liquidity, uint256 added0, uint256 added1) = _NFPM.mint(INFPM.MintParams
    ({
      token0: _TOKEN_0,
      token1: _TOKEN_1,
      fee: _ROUTE,
      tickLower: _MIN_TICK,
      tickUpper: _MAX_TICK,
      amount0Desired: addable0,
      amount1Desired: addable1,
      amount0Min: 0,
      amount1Min: 0,
      recipient: address(this),
      deadline: block.timestamp
    }));


    uint256 wusd = _wusd(added0, added1);


    IERC20(_USDT).safeTransferFrom(msg.sender, _REGISTRY.collector(), _fee(wusd));

    _nfts.add(nft);
    _nftOf[msg.sender] = nft;

    _provided[msg.sender] = true;
    _provision[nft] = Provision({ liquidity: liquidity, timestamp: uint48(block.timestamp), withdrawable: uint48(block.timestamp + 1 days) });

    _return(Returnance({ creditized: false, amount0: addable0.sub(added0), amount1: addable1.sub(added1) }), nft);


    if (referrer != address(0))
    {
      IFrontender(_REGISTRY.frontender()).refer(msg.sender, 100e18, referrer);
    }


    emit Provide(msg.sender, nft, wusd, referrer);
  }


  function _hasProvided () internal view
  {
    require(_provided[msg.sender], "!provided");
  }

  function _reprovision (uint256 nft) internal view returns (Provision memory)
  {
    Provision memory provision = _provision[nft];
    (,,,,,,, uint256 liquidity,,,,) = _NFPM.positions(nft);

    uint256 timestamp = uint256(provision.liquidity).mul(provision.timestamp).add(liquidity.mul(block.timestamp)).div(liquidity.add(provision.liquidity));


    return Provision({ liquidity: uint128(liquidity), timestamp: uint48(timestamp), withdrawable: uint48(block.timestamp + 1 days) });
  }

  function increase (uint256 addable0, uint256 addable1) external nonReentrant
  {
    _hasProvided();


    uint256 nft = _nftOf[msg.sender];


    IERC20(_TOKEN_0).safeTransferFrom(msg.sender, address(this), addable0);
    IERC20(_TOKEN_1).safeTransferFrom(msg.sender, address(this), addable1);


    (, uint256 added0, uint256 added1) = _NFPM.increaseLiquidity(INFPM.IncreaseLiquidityParams
    ({
      tokenId: nft,
      amount0Desired: addable0,
      amount1Desired: addable1,
      amount0Min: 0,
      amount1Min: 0,
      deadline: block.timestamp
    }));


    uint256 wusd = _wusd(added0, added1);


    IERC20(_USDT).safeTransferFrom(msg.sender, _REGISTRY.collector(), _fee(wusd));

    _provision[nft] = _reprovision(nft);

    _return(Returnance({ creditized: false, amount0: addable0.sub(added0), amount1: addable1.sub(added1) }), nft);


    emit Increase(msg.sender, nft, wusd);
  }


  function _collect (uint256 nft) internal
  {
    (uint256 collected0, uint256 collected1) = _NFPM.collect(INFPM.CollectParams
    ({
      tokenId: nft,
      recipient: address(this),
      amount0Max: type(uint128).max,
      amount1Max: type(uint128).max
    }));


    _return(Returnance({ creditized: true, amount0: collected0, amount1: collected1 }), nft);


    emit Collect(msg.sender, nft, _wusd(collected0, collected1));
  }

  function _decrease (uint256 nft, uint256 percentage) internal
  {
    _NFPM.decreaseLiquidity(INFPM.DecreaseLiquidityParams
    ({
      tokenId: nft,
      liquidity: uint128(percentage.mul(_provision[nft].liquidity).div(100e18)),
      amount0Min: 0,
      amount1Min: 0,
      deadline: block.timestamp
    }));


    (,,,,,,, uint128 liquidity,,,,) = _NFPM.positions(nft);


    _provision[nft].liquidity = liquidity;
  }

  function decrease (uint256 percentage) external nonReentrant
  {
    _hasProvided();


    uint256 nft = _nftOf[msg.sender];

    require(percentage > 0 && percentage < 100e18, "!valid %");
    require(block.timestamp > _provision[nft].withdrawable, "!withdrawable");


    _decrease(nft, percentage);
    _collect(nft);


    emit Decrease(msg.sender, nft);
  }

  function collect () external nonReentrant
  {
    _hasProvided();


    _collect(_nftOf[msg.sender]);
  }

  function withdraw () external nonReentrant
  {
    _hasProvided();


    uint256 nft = _nftOf[msg.sender];

    require(block.timestamp > _provision[nft].withdrawable, "!withdrawable");


    _decrease(nft, 100e18);
    _collect(nft);

    _nfts.remove(nft);
    _nftOf[msg.sender] = 0;
    _provided[msg.sender] = false;

    _NFPM.burn(nft);
    delete _provision[nft];


    emit Withdraw(msg.sender, nft);
  }


  function recharge () external
  {
    require(msg.sender == _WUSory, "!WUSory");


    _dischargestamp = block.timestamp.add(30 days);
  }
}