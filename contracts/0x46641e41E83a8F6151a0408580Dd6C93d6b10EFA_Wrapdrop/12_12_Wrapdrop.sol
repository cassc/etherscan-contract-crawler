// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IBART } from "./interfaces/IBART.sol";
import { IWUSD } from "./interfaces/IWUSD.sol";
import { IGlove } from "./interfaces/IGlove.sol";


contract Wrapdrop is ReentrancyGuard
{
  using BitMaps for BitMaps.BitMap;


  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _WUSD = 0x068E3563b1c19590F822c0e13445c4FA1b9EEFa5;
  address private constant _LOBS = 0x026224A2940bFE258D0dbE947919B62fE321F042;
  address private constant _BART = 0xb80fBF6cdb49c33dC6aE4cA11aF8Ac47b0b4C0f3;

  uint256 private constant _GATE = 765e18; // 764 + 1


  struct Drop
  {
    uint128 amount;
    uint128 credited;
  }


  BitMaps.BitMap private _lobby;
  BitMaps.BitMap private _barty;

  bool private _done;
  uint256 private _lot;
  uint256 private _epoch;
  uint256 private _claimed;

  mapping(address => Drop) private _drop;
  mapping(address => bool) private _dropped;


  event Claim(address account);
  event Collect(address account);


  constructor ()
  {
    _lot = 10e18;
    _epoch = IWUSD(_WUSD).snapshot().epoch;
  }


  function done () external view returns (bool)
  {
    return _done;
  }

  function claimed () external view returns (uint256)
  {
    return _claimed;
  }

  function claimer (address account) external view returns (bool)
  {
    return _dropped[account];
  }

  function status () external view returns (uint256, uint256)
  {
    return (_epoch, _lot);
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return (amount * percent) / 100_00;
  }

  function claim () external nonReentrant
  {
    uint256 wrapped = IERC20(_WUSD).balanceOf(msg.sender);
    (uint256 current, uint256 user) = (IWUSD(_WUSD).snapshot().epoch, IWUSD(_WUSD).epochOf(msg.sender));

    require(!_done, "done");
    require(!_dropped[msg.sender], "dropped");
    require(tx.origin == msg.sender, "who dis?");

    require(user > 0, "wrap");
    require(wrapped >= 1000e18, "smol");
    require(current > _epoch, "active");
    require(current - user == 1, "stale");


    uint256 lobs = IERC721Enumerable(_LOBS).balanceOf(msg.sender);
    uint256 barts = IERC721Enumerable(_BART).balanceOf(msg.sender);

    require(lobs >= 1 || barts >= 1, "shrimp squiggle");


    uint256 lob;
    bool undropped;

    for (uint256 i; i < lobs;)
    {
      lob = IERC721Enumerable(_LOBS).tokenOfOwnerByIndex(msg.sender, i);


      if (_lobby.get(lob))
      {
        undropped = true;
      }


      _lobby.set(lob);


      unchecked { i++; }
    }


    if (lobs == 0)
    {
      uint256 bart;
      bool marbled;

      for (uint256 j; j < barts;)
      {
        bart = IERC721Enumerable(_BART).tokenOfOwnerByIndex(msg.sender, j);


        if (!marbled)
        {
          marbled = IBART(_BART).tokenToStyle(bart) == 31;
        }


        if (_barty.get(bart))
        {
          undropped = true;
        }


        _barty.set(bart);


        unchecked { j++; }
      }


      require(marbled, "dull");
    }


    if (!undropped)
    {
      uint256 drop = lobs >= 1 ? _lot : (_lot / 2);


      _claimed += drop;
      _drop[msg.sender] = Drop({ amount: uint128(drop), credited: uint128(_percent(1e18, Math.min((wrapped * 100_00) / 100_000e18, 100_00))) });


      IERC20(_GLOVE).mint(address(this), drop);
    }


    _epoch = current;
    _dropped[msg.sender] = true;


    if (_claimed >= _GATE)
    {
      _done = true;
    }
    else if (_claimed >= 255e18)
    {
      _lot = _claimed >= 510e18 ? 2.5e18 : 5e18;
    }


    emit Claim(msg.sender);
  }

  function collect () external nonReentrant
  {
    require(_done, "!done");
    require(_dropped[msg.sender], "!dropped");


    IGlove(_GLOVE).transferCreditless(msg.sender, _drop[msg.sender].amount);
    IGlove(_GLOVE).creditize(msg.sender, _drop[msg.sender].credited);


    delete _drop[msg.sender];
    _dropped[msg.sender] = false;


    if (IERC20(_GLOVE).balanceOf(address(this)) == 0)
    {
      IAccessControl(_GLOVE).renounceRole(0xbe74a168a238bf2df7daa27dd5487ac84cb89ae44fd7e7d1e4b6397bfe51dcb8, address(this));
    }


    emit Collect(msg.sender);
  }
}