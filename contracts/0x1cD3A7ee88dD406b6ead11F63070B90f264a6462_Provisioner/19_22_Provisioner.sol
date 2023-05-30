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


contract Provisioner is IERC721Receiver, ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeToken for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;


  INFPM private constant _NFPM = INFPM(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint24 private constant _ROUTE = 1_0000;

  int24 private constant _MIN_TICK = -887200;
  int24 private constant _BIND_TICK = -230400;
  int24 private constant _MAX_TICK = 887200;


  enum Range { Bounded, Infinite }

  struct Decoded
  {
    bytes32 id;
    address token;
  }

  struct Returnance
  {
    bool creditized;
    address token;
    uint256 amount0;
    uint256 amount1;
  }

  struct Provision
  {
    uint128 liquidity;
    uint48 timestamp;
    uint48 withdrawable;
  }


  EnumerableSet.UintSet private _nfts;

  mapping(uint256 => Provision) private _provision;
  mapping(address => EnumerableSet.UintSet) private _nftsOf;
  mapping(address => mapping(bytes32 => bool)) private _provided;


  event Provide(address indexed account, bytes32 id, uint256 nft, uint256 amount, address referrer);
  event Increase(address indexed account, uint256 nft, uint256 amount);
  event Decrease(address indexed account, uint256 nft);
  event Collect(address indexed account, uint256 nft, uint256 amount);
  event Withdraw(address indexed account, bytes32 id, uint256 nft);


  constructor ()
  {
    IERC20(_USDT).safeApprove(address(_NFPM), type(uint128).max);
    IERC20(_USDC).safeApprove(address(_NFPM), type(uint128).max);
    IERC20(_GLOVE).safeApprove(address(_NFPM), type(uint128).max);
  }

  function onERC721Received (address, address, uint256, bytes calldata) external view override returns (bytes4)
  {
    require(msg.sender == address(_NFPM), "!NFPM");


    return 0x150b7a02;
  }


  function nfts () external view returns (uint256[] memory)
  {
    return _nfts.values();
  }

  function nftsOf (address account) external view returns (uint256[] memory)
  {
    return _nftsOf[account].values();
  }

  function provisionOf (uint256 nft) external view returns (Provision memory)
  {
    return _provision[nft];
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return amount.mul(percent).div(100_00);
  }


  function _fee (uint256 amount) internal pure returns (uint256)
  {
    return Math.max(100e6, _percent(amount, 1_00));
  }

  function _return (Returnance memory returnance, uint256 nft) internal
  {
    if (returnance.amount0 > 0)
    {
      IGlove(_GLOVE).transferCreditless(msg.sender, returnance.amount0);


      if (returnance.creditized)
      {
        IGlove(_GLOVE).creditize(msg.sender, _percent(returnance.amount0, Math.min(block.timestamp.sub(_provision[nft].timestamp).div(2 weeks) * 100, 100_00)));


        _provision[nft].timestamp = uint48(block.timestamp);
      }
    }

    if (returnance.amount1 > 0)
    {
      IERC20(returnance.token).safeTransfer(msg.sender, returnance.amount1);
    }
  }

  function _encode (Range range, address token) internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(range, _GLOVE, token));
  }

  function provide (Range range, address token, uint256 addable0, uint256 addable1, address referrer) external nonReentrant
  {
    bytes32 id = _encode(range, token);

    require(!_provided[msg.sender][id], "provided");
    require(token == _USDT || token == _USDC, "!valid");


    IERC20(_GLOVE).safeTransferFrom(msg.sender, address(this), addable0);
    IERC20(token).safeTransferFrom(msg.sender, address(this), addable1);


    (uint256 nft, uint128 liquidity, uint256 added0, uint256 added1) = _NFPM.mint(INFPM.MintParams
    ({
      token0: _GLOVE,
      token1: token,
      fee: _ROUTE,
      tickLower: range == Range.Bounded ? _BIND_TICK : _MIN_TICK,
      tickUpper: _MAX_TICK,
      amount0Desired: addable0,
      amount1Desired: addable1,
      amount0Min: 0,
      amount1Min: 0,
      recipient: address(this),
      deadline: block.timestamp
    }));


    IERC20(token).safeTransferFrom(msg.sender, _REGISTRY.collector(), _fee(added1));

    _nfts.add(nft);
    _nftsOf[msg.sender].add(nft);

    _provided[msg.sender][id] = true;
    _provision[nft] = Provision({ liquidity: liquidity, timestamp: uint48(block.timestamp), withdrawable: uint48(block.timestamp + 1 days) });

    _return(Returnance({ creditized: false, token: token, amount0: addable0.sub(added0), amount1: addable1.sub(added1) }), nft);


    if (referrer != address(0))
    {
      IFrontender(_REGISTRY.frontender()).refer(msg.sender, 100e18, referrer);
    }


    emit Provide(msg.sender, id, nft, added0, referrer);
  }


  function _isProvider (uint256 nft) internal view
  {
    require(_nftsOf[msg.sender].contains(nft), "!provider");
  }

  function _decode (uint256 nft) internal view returns (Decoded memory)
  {
    (,,, address token,, int24 tickLower,,,,,,) = _NFPM.positions(nft);


    return Decoded({ id: _encode(tickLower == _MIN_TICK ? Range.Infinite : Range.Bounded, token), token: token });
  }

  function _reprovision (uint256 nft) internal view returns (Provision memory)
  {
    Provision memory provision = _provision[nft];
    (,,,,,,, uint256 liquidity,,,,) = _NFPM.positions(nft);

    uint256 timestamp = uint256(provision.liquidity).mul(provision.timestamp).add(liquidity.mul(block.timestamp)).div(liquidity.add(provision.liquidity));


    return Provision({ liquidity: uint128(liquidity), timestamp: uint48(timestamp), withdrawable: uint48(block.timestamp + 1 days) });
  }

  function increase (uint256 nft, uint256 addable0, uint256 addable1) external nonReentrant
  {
    _isProvider(nft);


    Decoded memory decoded = _decode(nft);


    IERC20(_GLOVE).safeTransferFrom(msg.sender, address(this), addable0);
    IERC20(decoded.token).safeTransferFrom(msg.sender, address(this), addable1);


    (, uint256 added0, uint256 added1) = _NFPM.increaseLiquidity(INFPM.IncreaseLiquidityParams
    ({
      tokenId: nft,
      amount0Desired: addable0,
      amount1Desired: addable1,
      amount0Min: 0,
      amount1Min: 0,
      deadline: block.timestamp
    }));


    IERC20(decoded.token).safeTransferFrom(msg.sender, _REGISTRY.collector(), _fee(added1));

    _provision[nft] = _reprovision(nft);

    _return(Returnance({ creditized: false, token: decoded.token, amount0: addable0.sub(added0), amount1: addable1.sub(added1) }), nft);


    emit Increase(msg.sender, nft, added0);
  }


  function _collect (Decoded memory decoded, uint256 nft) internal
  {
    (uint256 collected0, uint256 collected1) = _NFPM.collect(INFPM.CollectParams
    ({
      tokenId: nft,
      recipient: address(this),
      amount0Max: type(uint128).max,
      amount1Max: type(uint128).max
    }));


    _return(Returnance({ creditized: true, token: decoded.token, amount0: collected0, amount1: collected1 }), nft);


    emit Collect(msg.sender, nft, collected0);
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

  function decrease (uint256 nft, uint256 percentage) external nonReentrant
  {
    _isProvider(nft);
    require(percentage > 0 && percentage < 100e18, "!valid %");
    require(block.timestamp > _provision[nft].withdrawable, "!withdrawable");


    _decrease(nft, percentage);
    _collect(_decode(nft), nft);


    emit Decrease(msg.sender, nft);
  }

  function collect (uint256 nft) external nonReentrant
  {
    _isProvider(nft);


    _collect(_decode(nft), nft);
  }

  function withdraw (uint256 nft) external nonReentrant
  {
    _isProvider(nft);
    require(block.timestamp > _provision[nft].withdrawable, "!withdrawable");


    Decoded memory decoded = _decode(nft);


    _decrease(nft, 100e18);
    _collect(decoded, nft);

    _nfts.remove(nft);
    _nftsOf[msg.sender].remove(nft);
    _provided[msg.sender][decoded.id] = false;

    _NFPM.burn(nft);
    delete _provision[nft];


    emit Withdraw(msg.sender, decoded.id, nft);
  }
}