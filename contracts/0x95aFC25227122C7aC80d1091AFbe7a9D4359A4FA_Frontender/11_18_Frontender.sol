// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IWUSD } from "./interfaces/IWUSD.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IFrontender } from "./interfaces/IFrontender.sol";


contract Frontender is IFrontender, AccessControlEnumerable, ReentrancyGuard
{
  using SafeToken for IERC20;


  bytes32 public constant REFEREE_ROLE = keccak256("REFEREE_ROLE");

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _WUSD = 0x068E3563b1c19590F822c0e13445c4FA1b9EEFa5;
  address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  uint256 private constant _MAX_GLOVE = 2e18;
  uint256 private constant _FEE = 100e6;


  mapping(address => uint256) private _referred;


  event Register(address indexed referrer);
  event Deregister(address indexed referrer);


  constructor ()
  {
    _setupRole(REFEREE_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(REFEREE_ROLE, DEFAULT_ADMIN_ROLE);
  }


  function referralsOf (address referrer) external view returns (uint256)
  {
    return _referred[referrer];
  }


  function _registered (address account) internal view returns (bool)
  {
    return _referred[account] > 0;
  }

  function isRegistered (address account) external view returns (bool)
  {
    return _registered(account);
  }


  function _isUnwrapped () internal view
  {
    require(IWUSD(_WUSD).epochOf(msg.sender) == 0, "wrapped");
  }

  function register () external nonReentrant
  {
    _isUnwrapped();
    require(!_registered(msg.sender), "registered");


    uint256 gloves = IERC20(_GLOVE).balanceOf(msg.sender);


    _referred[msg.sender] = 1e18;

    IERC20(_USDT).safeTransferFrom(msg.sender, _REGISTRY.collector(), _FEE);


    if (gloves < _MAX_GLOVE)
    {
      IGlove(_GLOVE).mintCreditless(msg.sender, _MAX_GLOVE - gloves);
    }


    emit Register(msg.sender);
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return (amount * percent) / 100_00;
  }

  function deregister () external nonReentrant
  {
    _isUnwrapped();
    require(_registered(msg.sender), "!registered");


    uint256 creditless = IGlove(_GLOVE).creditlessOf(msg.sender);

    uint256 credits = _percent(creditless, Math.min((_referred[msg.sender] / 100_000e18) * 100, 100_00));


    _referred[msg.sender] = 0;

    IGlove(_GLOVE).burn(msg.sender, creditless - credits);
    IGlove(_GLOVE).creditize(msg.sender, credits);


    emit Deregister(msg.sender);
  }

  function refer (address account, uint256 amount, address referrer) external
  {
    require(hasRole(REFEREE_ROLE, msg.sender), "!referee");


    if (referrer != account && _registered(referrer))
    {
      _referred[referrer] += amount;
    }
  }
}