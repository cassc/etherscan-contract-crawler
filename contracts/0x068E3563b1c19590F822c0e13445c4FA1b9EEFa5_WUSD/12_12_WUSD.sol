// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IFrontender } from "./interfaces/IFrontender.sol";
import { Snapshot, IWUSD } from "./interfaces/IWUSD.sol";


contract WUSD is IWUSD, ReentrancyGuard
{
  using SafeToken for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;


  bytes32 private constant _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 private constant _DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  bytes32 private constant _NAME_HASH = keccak256("Wrapped USD");
  bytes32 private constant _VERSION_HASH = keccak256("1");


  ISwapRouter private constant _ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 private constant _MIN_GLOVABLE = 100e18;
  uint256 private constant _MID_GLOVE = 0.01e18;
  uint256 private constant _MAX_GLOVE = 2e18;
  uint256 private constant _EPOCH = 100_000e18;

  uint24 private constant _ROUTE = 500;


  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;


  Snapshot private _snapshot;
  EnumerableSet.AddressSet private _fiatcoins;


  uint256 private _totalSupply;

  mapping(address => uint256) private _epoch;
  mapping(address => uint256) private _decimal;

  mapping(address => uint256) private _nonce;

  mapping(address => uint256) private _balance;
  mapping(address => mapping(address => uint256)) private _allowance;


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Wrap(address indexed account, address fiatcoin, uint256 amount, address referrer);
  event Unwrap(address indexed account, address fiatcoin, uint256 amount);


  constructor (address[] memory fiatcoins)
  {
    uint256 decimal;
    address fiatcoin;

    for (uint256 i; i < fiatcoins.length;)
    {
      fiatcoin = fiatcoins[i];
      decimal = IERC20(fiatcoin).decimals();

      _fiatcoins.add(fiatcoin);
      _decimal[fiatcoin] = decimal;

      IERC20(fiatcoin).safeApprove(address(_ROUTER), type(uint128).max);


      unchecked { i++; }
    }


    _CACHED_THIS = address(this);
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _separator();


    _snapshot = Snapshot({ epoch: 1, last: 0, cumulative: 0 });
  }

  function name () public pure returns (string memory)
  {
    return "Wrapped USD";
  }

  function symbol () public pure returns (string memory)
  {
    return "WUSD";
  }

  function decimals () public pure returns (uint8)
  {
    return 18;
  }

  function totalSupply () public view returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf (address account) public view returns (uint256)
  {
    return _balance[account];
  }


  function snapshot () public view returns (Snapshot memory)
  {
    return _snapshot;
  }

  function epochOf (address account) public view returns (uint256)
  {
    return _epoch[account];
  }


  function _separator () private view returns (bytes32)
  {
    return keccak256(abi.encode(_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
  }

  function DOMAIN_SEPARATOR () public view returns (bytes32)
  {
    return (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) ? _CACHED_DOMAIN_SEPARATOR : _separator();
  }

  function nonces (address owner) public view returns (uint256)
  {
    return _nonce[owner];
  }

  function allowance (address owner, address spender) public view returns (uint256)
  {
    return _allowance[owner][spender];
  }


  function _approve (address owner, address spender, uint256 amount) internal
  {
    _allowance[owner][spender] = amount;


    emit Approval(owner, spender, amount);
  }

  function approve (address spender, uint256 amount) public returns (bool)
  {
    _approve(msg.sender, spender, amount);


    return true;
  }

  function increaseAllowance (address spender, uint256 amount) public returns (bool)
  {
    _approve(msg.sender, spender, _allowance[msg.sender][spender] + amount);


    return true;
  }

  function decreaseAllowance (address spender, uint256 amount) public returns (bool)
  {
    uint256 currentAllowance = _allowance[msg.sender][spender];

    require(currentAllowance >= amount, "WUSD: decreasing < 0");


    unchecked
    {
      _approve(msg.sender, spender, currentAllowance - amount);
    }


    return true;
  }

  function permit (address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public
  {
    require(block.timestamp <= deadline, "WUSD: expired deadline");


    bytes32 hash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _nonce[owner]++, deadline));
    address signer = ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hash)), v, r, s);

    require(signer != address(0) && signer == owner, "WUSD: !valid signature");


    _approve(owner, spender, value);
  }


  function _transfer (address from, address to, uint256 amount) internal
  {
    require(to != address(0), "WUSD: transfer to 0 addr");


    uint256 balance = _balance[from];

    require(balance >= amount, "WUSD: amount > balance");


    unchecked
    {
      _balance[from] = balance - amount;
      _balance[to] += amount;
    }


    emit Transfer(from, to, amount);
  }

  function transfer (address to, uint256 amount) public returns (bool)
  {
    _transfer(msg.sender, to, amount);


    return true;
  }

  function transferFrom (address from, address to, uint256 amount) public returns (bool)
  {
    uint256 currentAllowance = _allowance[from][msg.sender];


    if (currentAllowance != type(uint256).max)
    {
      require(currentAllowance >= amount, "WUSD: !enough allowance");


      unchecked
      {
        _approve(from, msg.sender, currentAllowance - amount);
      }
    }


    _transfer(from, to, amount);


    return true;
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return (amount * percent) / 100_00;
  }

  function _normalize (uint256 amount, uint256 decimal) internal pure returns (uint256)
  {
    return (amount * 1e18) / (10 ** decimal);
  }

  function _denormalize (uint256 amount, uint256 decimal) internal pure returns (uint256)
  {
    return (amount * (10 ** decimal)) / 1e18;
  }


  function _isFiatcoin (address token) internal view
  {
    require(_fiatcoins.contains(token), "WUSD: !fiatcoin");
  }


  function _snap (uint256 wrapping) internal
  {
    Snapshot memory snap = _snapshot;


    if ((snap.cumulative - snap.last) >= _EPOCH)
    {
      _snapshot.epoch = snap.epoch + 1;
      _snapshot.last = snap.cumulative;
    }

    if (wrapping >= _MIN_GLOVABLE || _epoch[msg.sender] > 0)
    {
      _epoch[msg.sender] = _snapshot.epoch;
    }


    _snapshot.cumulative = snap.cumulative + uint112(wrapping);
  }

  function _englove (uint256 wrapping) internal
  {
    uint256 gloves = IGlove(_GLOVE).balanceOf(msg.sender);


    if (wrapping >= _MIN_GLOVABLE && gloves < _MAX_GLOVE)
    {
      IGlove(_GLOVE).mintCreditless(msg.sender, Math.min(_MAX_GLOVE - gloves, wrapping > 1_000e18 ? ((_MAX_GLOVE * wrapping) / _EPOCH) : ((_MID_GLOVE * wrapping) / 1_000e18)));
    }
  }

  function _mint (address account, uint256 amount) internal
  {
    require(account != address(0), "WUSD: mint to 0 addr");


    _totalSupply += amount;


    unchecked
    {
      _balance[account] += amount;
    }


    emit Transfer(address(0), account, amount);
  }

  function _parse (uint256 amount, uint256 decimal) internal pure returns (uint256, uint256)
  {
    return (Math.max(10 ** decimal, _percent(amount, 1_00)), _normalize(amount, decimal));
  }

  function wrap (address fiatcoin, uint256 amount, address referrer) external nonReentrant
  {
    _isFiatcoin(fiatcoin);
    require(amount > 0, "WUSD: wrap(0)");


    (uint256 fee, uint256 wrapping) = _parse(amount, _decimal[fiatcoin]);


    _snap(wrapping);
    _mint(msg.sender, wrapping);

    _englove(wrapping);
    IERC20(fiatcoin).safeTransferFrom(msg.sender, address(this), amount + fee);


    if (fiatcoin != _USDT && fiatcoin != _USDC)
    {
      _ROUTER.exactInputSingle(ISwapRouter.ExactInputSingleParams
      ({
        tokenIn: fiatcoin,
        tokenOut: _USDC,
        fee: fiatcoin != 0x0000000000085d4780B73119b644AE5ecd22b376 ? _ROUTE : 100,
        recipient: _REGISTRY.collector(),
        deadline: block.timestamp,
        amountIn: fee,
        amountOutMinimum: _percent(_denormalize(_normalize(fee, _decimal[fiatcoin]), 6), 95_00),
        sqrtPriceLimitX96: 0
      }));
    }
    else
    {
      IERC20(fiatcoin).safeTransfer(_REGISTRY.collector(), fee);
    }


    if (referrer != address(0))
    {
      IFrontender(_REGISTRY.frontender()).refer(msg.sender, wrapping, referrer);
    }


    emit Wrap(msg.sender, fiatcoin, amount, referrer);
  }


  function _burn (address account, uint256 amount) internal
  {
    uint256 balance = _balance[account];

    require(balance >= amount, "WUSD: burn > balance");


    unchecked
    {
      _balance[account] = balance - amount;
      _totalSupply -= amount;
    }


    emit Transfer(account, address(0), amount);
  }

  function _deglove (uint256 amount, uint256 balance) internal
  {
    uint256 creditless = IGlove(_GLOVE).creditlessOf(msg.sender);

    uint256 credits = _percent(creditless, Math.min((amount * 100_00) / balance, (_snapshot.epoch - _epoch[msg.sender]) * 100));


    if (_epoch[msg.sender] > 0)
    {
      if (amount == balance)
      {
        _epoch[msg.sender] = 0;

        IGlove(_GLOVE).burn(msg.sender, creditless - credits);
      }
      else
      {
        _epoch[msg.sender] = _snapshot.epoch;
      }


      IGlove(_GLOVE).creditize(msg.sender, credits);
    }
  }

  function unwrap (address fiatcoin, uint256 amount) external nonReentrant
  {
    _isFiatcoin(fiatcoin);


    uint256 balance = _balance[msg.sender];
    uint256 unwrapping = _denormalize(amount, _decimal[fiatcoin]);

    require(amount > 0, "WUSD: unwrap(0)");
    require((IERC20(fiatcoin).balanceOf(address(this)) - (10 ** _decimal[fiatcoin])) >= unwrapping, "WUSD: !enough fiatcoin");


    _burn(msg.sender, amount);
    _deglove(amount, balance);
    IERC20(fiatcoin).safeTransfer(msg.sender, unwrapping);


    emit Unwrap(msg.sender, fiatcoin, amount);
  }
}