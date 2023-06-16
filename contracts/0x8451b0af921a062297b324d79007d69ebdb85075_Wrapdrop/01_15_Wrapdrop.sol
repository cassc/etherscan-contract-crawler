// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IBART } from "./interfaces/IBART.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IWUSD } from "./interfaces/IWUSD.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IBypasser } from "./interfaces/IBypasser.sol";


contract Wrapdrop is ReentrancyGuard
{
  using BitMaps for BitMaps.BitMap;
  using EnumerableSet for EnumerableSet.AddressSet;


  IBypasser private constant _BYPASSER = IBypasser(0x9ca5b4C70A95Dc5910E6328eB2b96e7cE7372183);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _WUSD = 0x068E3563b1c19590F822c0e13445c4FA1b9EEFa5;

  address private constant _LOBS = 0x026224A2940bFE258D0dbE947919B62fE321F042;
  address private constant _BART = 0xb80fBF6cdb49c33dC6aE4cA11aF8Ac47b0b4C0f3;

  uint256 private constant _GATE = 765e18;


  struct Epoch
  {
    uint128 curr;
    uint128 last;
  }

  struct Entrance
  {
    bool lobbed;
    uint16 nfts;
    uint112 drop;
    uint112 credit;
  }

  struct Selectable
  {
    uint128 lobsters;
    uint128 marblers;
  }


  bool private _ended;
  uint256 private _drop;
  uint256 private _dropped;
  uint256 private _collected;

  Epoch private _epoch;

  uint256 private _round;
  uint256 private _squeezestamp;

  BitMaps.BitMap private _selecsters;
  BitMaps.BitMap private _selecrbles;

  mapping(address => bool) private _selected;
  mapping(address => Entrance) private _entrance;
  mapping(uint256 => Selectable) private _selectable;

  mapping(uint256 => BitMaps.BitMap) private _epsters;
  mapping(uint256 => BitMaps.BitMap) private _eprbles;

  mapping(uint256 => EnumerableSet.AddressSet) private _enterers;


  event Enter(address account);
  event Select(address account, uint256 amount);
  event Collect(address account, uint256 amount);
  event Squeeze(address account, uint256 amount);


  constructor (Entrance[] memory prentrances, address[] memory preselected, uint256[] memory usesters, uint256[] memory userbles)
  {
    require(prentrances.length == preselected.length, "!=");


    _round = 1;
    _epoch = Epoch({ last: 0, curr: IWUSD(_WUSD).snapshot().epoch });
    _selectable[_epoch.curr] = Selectable({ lobsters: 0, marblers: 0 });

    _squeezestamp = block.timestamp + 60 days;

    _dropped = 260e18;
    _drop = 5e18;


    for (uint256 i; i < preselected.length;)
    {
      _entrance[preselected[i]] = prentrances[i];
      _selected[preselected[i]] = true;


      unchecked { i++; }
    }

    for (uint256 j; j < usesters.length;)
    {
      _selecsters.set(usesters[j]);


      unchecked { j++; }
    }

    for (uint256 k; k < userbles.length;)
    {
      _selecrbles.set(userbles[k]);


      unchecked { k++; }
    }
  }

  function ended () external view returns (bool)
  {
    return _ended;
  }


  function round () external view returns (uint256)
  {
    return _round;
  }


  function dropped () external view returns (uint256)
  {
    return _dropped;
  }

  function collected () external view returns (uint256)
  {
    return _collected;
  }


  function selected (address account) external view returns (bool)
  {
    return _selected[account];
  }

  function entered (address account, uint256 epoch) external view returns (bool)
  {
    if (epoch == 0)
    {
      return _enterers[_epoch.last].contains(account) || _enterers[_epoch.curr].contains(account);
    }
    else
    {
      return _enterers[epoch].contains(account);
    }
  }


  function status () external view returns (Selectable memory, Epoch memory, uint256)
  {
    return (_selectable[_epoch.curr], _epoch, _drop);
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return (amount * percent) / 100_00;
  }


  function _select (Epoch memory epoch, uint256 currepoch, bool finish) internal
  {
    uint256 target;
    address selection;
    Entrance memory entrance;


    if (!finish)
    {
      target = uint256(keccak256(abi.encodePacked(_enterers[epoch.last].at(25), _enterers[epoch.curr].at(49), currepoch, epoch.last, block.difficulty))) % 50;
      selection = _enterers[epoch.last].at(target);
      entrance = _entrance[selection];


      uint256 nfts = IERC721Enumerable(entrance.lobbed ? _LOBS : _BART).balanceOf(selection);

      for (uint256 i; i < nfts;)
      {
        if (entrance.lobbed)
        {
          _selecsters.set(IERC721Enumerable(_LOBS).tokenOfOwnerByIndex(selection, i));
        }
        else
        {
          _selecrbles.set(IERC721Enumerable(_BART).tokenOfOwnerByIndex(selection, i));
        }


        unchecked { i++; }
      }


      if (nfts < entrance.nfts)
      {
        _entrance[selection].credit = 0;
      }
    }
    else
    {
      target = uint256(keccak256(abi.encodePacked(_enterers[epoch.last].at(49), _enterers[epoch.curr].at(25), msg.sender, currepoch, block.difficulty))) % 51;
      selection = target == 50 ? msg.sender : _enterers[epoch.curr].at(target);
      entrance = _entrance[selection];
    }


    _selected[selection] = true;
    _dropped += entrance.drop;


    if (_dropped >= 510e18)
    {
      _drop = 2.5e18;
    }


    emit Select(selection, entrance.drop);
  }

  function enter () external nonReentrant
  {
    require(!_ended, "ended");
    require(!_selected[msg.sender], "selected");
    require(msg.sender == tx.origin, "who dis?");


    Epoch memory epoch = _epoch;
    uint256 wrapped = IERC20(_WUSD).balanceOf(msg.sender);
    (uint256 currepoch, uint256 usepoch) = (IWUSD(_WUSD).snapshot().epoch, IWUSD(_WUSD).epochOf(msg.sender));

    if (usepoch == 0)
    {
      uint256 pass = _BYPASSER.passOf(msg.sender).last;


      require(pass > 0 && (_round - pass) <= 10, "wrap");
    }
    else
    {
      require(usepoch >= epoch.curr, "stale");
    }

    require(wrapped >= 1000e18, "smol");
    require(!_enterers[epoch.last].contains(msg.sender), "wait");
    require(!_enterers[epoch.curr].contains(msg.sender), "entered");


    uint256 loblance = IERC721Enumerable(_LOBS).balanceOf(msg.sender);
    bool lobbed = loblance > 0;
    uint256 marlance;

    if (!lobbed)
    {
      marlance = IERC721Enumerable(_BART).balanceOf(msg.sender);

      require(marlance > 0, "shrimp squiggle");
    }


    uint256 nft;
    bool outside;

    for (uint256 i; i < loblance;)
    {
      nft = IERC721Enumerable(_LOBS).tokenOfOwnerByIndex(msg.sender, i);


      if (_epsters[epoch.last].get(nft) || _epsters[epoch.curr].get(nft) || _selecsters.get(nft))
      {
        outside = true;
      }


      _epsters[epoch.curr].set(nft);


      unchecked { i++; }
    }


    if (!lobbed)
    {
      bool marbled;

      for (uint256 j; j < marlance;)
      {
        nft = IERC721Enumerable(_BART).tokenOfOwnerByIndex(msg.sender, j);


        if (!marbled)
        {
          marbled = IBART(_BART).tokenToStyle(nft) == 31;
        }


        if (_eprbles[epoch.last].get(nft) || _eprbles[epoch.curr].get(nft) || _selecrbles.get(nft))
        {
          outside = true;
        }


        _eprbles[epoch.curr].set(nft);


        unchecked { j++; }
      }


      require(marbled, "dull");
    }


    if (!outside)
    {
      if (_enterers[epoch.curr].length() == 50)
      {
        require(currepoch > epoch.curr, "next");


        if (epoch.last > 0)
        {
          _round += 1;

          _select(epoch, currepoch, false);
        }


        _epoch = Epoch({ last: epoch.curr, curr: uint128(currepoch) });
        _selectable[currepoch] = Selectable({ lobsters: 0, marblers: 0 });
      }


      if (lobbed)
      {
        require(_selectable[_epoch.curr].lobsters < 25, "packed");


        _selectable[_epoch.curr].lobsters += 1;
      }
      else
      {
        require(_selectable[_epoch.curr].marblers < 25, "molded");


        _selectable[_epoch.curr].marblers += 1;
      }


      _enterers[_epoch.curr].add(msg.sender);
      _entrance[msg.sender] = Entrance({ lobbed: lobbed, nfts: uint16(lobbed ? loblance : marlance), drop: uint112(lobbed ? _drop : (_drop / 2)), credit: uint112(_percent(1e18, Math.min((wrapped * 100_00) / 100_000e18, 100_00))) });
    }


    if (_dropped >= _GATE)
    {
      _ended = true;

      _select(epoch, currepoch, true);
    }


    emit Enter(msg.sender);
  }


  function _canCollect () internal view
  {
    uint256 usepoch = IWUSD(_WUSD).epochOf(msg.sender);

    require(_selected[msg.sender], "!selected");
    require(usepoch == 0 || usepoch == IWUSD(_WUSD).snapshot().epoch, "dipper");
  }

  function collect () external nonReentrant
  {
    _canCollect();
    require(_ended, "!ended");


    (uint256 drop, uint256 credit) = (_entrance[msg.sender].drop, _entrance[msg.sender].credit);


    IGlove(_GLOVE).mintCreditless(msg.sender, drop);
    IGlove(_GLOVE).creditize(msg.sender, credit);


    _collected += drop;
    _selected[msg.sender] = false;
    delete _entrance[msg.sender];


    if (_collected >= _GATE)
    {
      IAccessControl(_GLOVE).renounceRole(0xbe74a168a238bf2df7daa27dd5487ac84cb89ae44fd7e7d1e4b6397bfe51dcb8, address(this));
    }


    emit Collect(msg.sender, drop);
  }

  function squeeze () external nonReentrant
  {
    _canCollect();
    require(!_ended, "collect");
    require(block.timestamp > _squeezestamp, "!squeezable");


    uint256 drop = _entrance[msg.sender].drop;


    IGlove(_GLOVE).mintCreditless(msg.sender, drop / 2);


    _collected += drop;
    delete _entrance[msg.sender];


    if (drop > 0)
    {
      _squeezestamp = block.timestamp + 1 weeks;


      emit Squeeze(msg.sender, drop);
    }
  }
}