// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IUniswapV3Pool as IUniPool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IWUSD } from "./interfaces/IWUSD.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IWrapdrop } from "./interfaces/IWrapdrop.sol";
import { Range, IProvisioner } from "./interfaces/IProvisioner.sol";


contract Bypasser is ReentrancyGuard
{
  using SafeToken for IERC20;


  IUniPool private constant _POOL = IUniPool(0xB89F65D6c7d33A35Da7C01934e310a6f40E18A1f);
  IWrapdrop private constant _WRAPDROP = IWrapdrop(0x8451b0Af921A062297b324D79007d69eBdB85075);

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);
  IProvisioner private constant _PROVISIONER = IProvisioner(0x1cD3A7ee88dD406b6ead11F63070B90f264a6462);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _WUSD = 0x068E3563b1c19590F822c0e13445c4FA1b9EEFa5;
  address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 private constant _MAX_PRICE = 1456195216270955103206513029158776779468408838535;
  uint256 private constant _MIN_PRICE = 787149618249685149291181;
  uint256 private constant _MULTIPLIER = 1810459682468736135;

  uint256 private constant _MIN = 1000e6;
  uint256 private constant _LIQ = 420e6;


  struct Pass
  {
    uint32 init;
    uint32 last;
    uint128 liquidity;
  }

  struct Prevision
  {
    uint64 nft;
    uint32 providers;
    uint128 liquidity;
  }


  Prevision private _prevision;

  mapping(address => Pass) private _pass;


  event Bypass(address account, uint256 amount, uint256 liquidity);
  event Refresh(address account, uint256 amount);
  event Forfeit(address account, uint256 liquidity);


  constructor ()
  {
    IERC20(_USDC).safeApprove(_WUSD, type(uint128).max);
    IERC20(_USDC).safeApprove(address(_PROVISIONER), type(uint128).max);
    IERC20(_GLOVE).safeApprove(address(_PROVISIONER), type(uint128).max);


    _PROVISIONER.provide(Range.Bounded, _USDC, 3575333364652851, 1e6, address(0));


    uint256 nft = _PROVISIONER.nftsOf(address(this))[0];


    _prevision = Prevision({ nft: uint64(nft), providers: 1, liquidity: _PROVISIONER.provisionOf(nft).liquidity });
  }


  function bypassing (address account) external view returns (bool)
  {
    return _pass[account].init > 0 && (_WRAPDROP.round() - _pass[account].last) <= 10;
  }

  function passOf (address account) external view returns (Pass memory)
  {
    return _pass[account];
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return (amount * percent) / 100_00;
  }


  function _isOpen () internal view
  {
    require(!_WRAPDROP.ended(), "ended");
  }

  function _canBypass (uint256 amount) internal view
  {
    require(amount >= _MIN, "smol");
    require(msg.sender == tx.origin, "who dis?");
    require(IWUSD(_WUSD).epochOf(msg.sender) == 0, "wrapping");
  }

  function _redenominate (uint256 amount) internal pure returns (uint256)
  {
    return (amount * 1e18) / 1e6;
  }

  function bypass (uint256 amount, address referrer) external nonReentrant
  {
    _isOpen();
    _canBypass(amount);
    require(_pass[msg.sender].init == 0, "bypassed");


    Prevision memory prevision = _prevision;

    (uint256 current,,,,,,) = _POOL.slot0();
    uint256 glovision = (_MULTIPLIER * (_MAX_PRICE - current)) / (current * (current - _MIN_PRICE));


    IERC20(_USDC).safeTransferFrom(msg.sender, address(this), _LIQ + amount + _percent(amount, 1_00) + 100e6);
    IERC20(_GLOVE).safeTransferFrom(msg.sender, address(this), glovision);

    _PROVISIONER.increase(prevision.nft, glovision, _LIQ);

    IWUSD(_WUSD).wrap(_USDC, amount, referrer);
    IERC20(_WUSD).safeTransfer(msg.sender, _redenominate(amount));


    uint256 round = _WRAPDROP.round();
    uint256 liquidity = _PROVISIONER.provisionOf(prevision.nft).liquidity;


    _prevision.providers += 1;
    _prevision.liquidity = uint128(liquidity);
    _pass[msg.sender] = Pass({ init: uint32(round), last: uint32(round), liquidity: uint128(liquidity - prevision.liquidity) });


    emit Bypass(msg.sender, amount, liquidity - prevision.liquidity);
  }


  function refresh (uint256 amount, address referrer) external nonReentrant
  {
    _isOpen();
    _canBypass(amount);
    require(_pass[msg.sender].init != 0, "!bypassed");


    uint256 fee = _percent(amount, 1_00);
    uint256 required = Math.max(100e6, fee);


    IERC20(_USDC).safeTransferFrom(msg.sender, address(this), amount + required);

    IWUSD(_WUSD).wrap(_USDC, amount, referrer);
    IERC20(_WUSD).safeTransfer(msg.sender, _redenominate(amount));


    if (required - fee > 0)
    {
      IERC20(_USDC).safeTransfer(_REGISTRY.collector(), required - fee);
    }


    _pass[msg.sender].last = uint32(_WRAPDROP.round());


    emit Refresh(msg.sender, amount);
  }


  function _deprovision () internal
  {
    if (_prevision.providers == 1 && _WRAPDROP.ended())
    {
      _PROVISIONER.withdraw(_prevision.nft);

      IWUSD(_WUSD).unwrap(_USDC, 1e18);
      IGlove(_GLOVE).burn(address(this), IERC20(_GLOVE).balanceOf(address(this)));
      IERC20(_USDC).safeTransfer(_REGISTRY.collector(), IERC20(_USDC).balanceOf(address(this)));

      IAccessControl(_GLOVE).renounceRole(0xbe74a168a238bf2df7daa27dd5487ac84cb89ae44fd7e7d1e4b6397bfe51dcb8, address(this));
    }
  }

  function forfeit () external nonReentrant
  {
    Pass memory pass = _pass[msg.sender];

    require(pass.init != 0, "!bypassed");
    require(IWUSD(_WUSD).epochOf(msg.sender) == 0, "wrapping");


    Prevision memory prevision = _prevision;


    _PROVISIONER.collect(prevision.nft);

    IGlove(_GLOVE).burn(address(this), IERC20(_GLOVE).balanceOf(address(this)) - 2e18);
    IERC20(_USDC).safeTransfer(_REGISTRY.collector(), IERC20(_USDC).balanceOf(address(this)) - 1e6);

    _PROVISIONER.decrease(prevision.nft, (pass.liquidity * 100e18) / prevision.liquidity);

    IERC20(_USDC).safeTransfer(msg.sender, IERC20(_USDC).balanceOf(address(this)) - 1e6);
    IGlove(_GLOVE).transferCreditless(msg.sender, IERC20(_GLOVE).balanceOf(address(this)) - 2e18);


    if (_WRAPDROP.round() - pass.init >= 50)
    {
      IGlove(_GLOVE).creditize(msg.sender, 1e18);
    }


    delete _pass[msg.sender];


    _prevision.providers -= 1;
    _prevision.liquidity = _PROVISIONER.provisionOf(prevision.nft).liquidity;


    _deprovision();


    emit Forfeit(msg.sender, pass.liquidity);
  }

  function cleanse () external nonReentrant
  {
    _deprovision();
  }
}