// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/*----------------------------------------------------------------------------------------------------+

██████╗░██╗░░██╗░█████╗░███████╗███╗░░██╗██╗██╗░░██╗   ██████╗░███████╗██╗░░░██╗██╗██╗░░░██╗███████╗
██╔══██╗██║░░██║██╔══██╗██╔════╝████╗░██║██║╚██╗██╔╝   ██╔══██╗██╔════╝██║░░░██║██║██║░░░██║██╔════╝
██████╔╝███████║██║░░██║█████╗░░██╔██╗██║██║░╚███╔╝░   ██████╔╝█████╗░░╚██╗░██╔╝██║╚██╗░██╔╝█████╗░░
██╔═══╝░██╔══██║██║░░██║██╔══╝░░██║╚████║██║░██╔██╗░   ██╔══██╗██╔══╝░░░╚████╔╝░██║░╚████╔╝░██╔══╝░░
██║░░░░░██║░░██║╚█████╔╝███████╗██║░╚███║██║██╔╝╚██╗   ██║░░██║███████╗░░╚██╔╝░░██║░░╚██╔╝░░███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═╝░░╚══╝╚═╝╚═╝░░╚═╝   ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝


𝙊𝙣𝙚 𝘾𝙡𝙞𝙘𝙠 𝙄𝙣𝙨𝙩𝙖𝙣𝙩 𝙍𝙚𝙫𝙞𝙫𝙚:
The token has the ability to instantly relaunch itself every optimised opportunity!

𝘼𝙣𝙩𝙞-𝙙𝙪𝙢𝙥 𝙛𝙡𝙤𝙤𝙧 𝙥𝙧𝙞𝙘𝙚:
A dynamic floor price is set in which selling below it will incur a higher tax (50%).

𝙍𝙚𝙫𝙞𝙫𝙚 𝙙𝘼𝙥𝙥:
New and innovative solution for diamond holders of projects which have “died” whereby
the project owner can merge their holders and LP seamlessly into Phoenix Revive.

Website: https://phoenixrevive.io/
Telegram: http://t.me/PhoenixRevive
Announcements: https://t.me/PhoenixReviveNews
Twitter: https://twitter.com/PhoenixReviveW3
Discord: https://discord.gg/WKQNpKPjBf
Reddit: https://www.reddit.com/r/PhoenixRevive/
YouTube: https://www.youtube.com/channel/UC7nH1TMvY_6J-EvAyTc2G_Q
Email: [email protected]

𝙏𝙖𝙭 𝙎𝙮𝙨𝙩𝙚𝙢:
Buy: 5%, Sell: 5%
Treasury: 1%, Marketing: 2%, Liquidity Pool: 2%

**Note: When selling below floor price, sell tax will be 50%, half of which will be burned.

+----------------------------------------------------------------------------------------------------*/

import "./interfaces/IPhoenixTracker.sol";
import "./interfaces/IPhoenix.sol";
import "./interfaces/ISwapFactory.sol";
import "./libraries/Numbers.sol";
import "./libraries/Router.sol";
import "./PhoenixCommon.sol";

contract PhoenixRevive is IPhoenix, PhoenixCommon {
  using Numbers for uint256;

  uint8 public constant decimals = 18;
  bool public ended;
  bool private _liquid;
  uint256[45] private __gap;

  function initialize(address tracker) public initializer {
    __PhoenixCommon_init();
    _otherAddr = tracker;
    _router = IPhoenixTracker(_otherAddr).router();
    _currency = _router.WETH();
    _pair = ISwapFactory(_router.factory()).createPair(_currency, _contractAddress);
    _pathBuy = Router.path(_currency, _contractAddress);
    _pathSell = Router.path(_contractAddress, _currency);
  }

  function name() external view returns (string memory) {
    IPhoenixTracker tracker = IPhoenixTracker(_otherAddr);
    return ended ? tracker.tokenNameExpired() : tracker.tokenName();
  }

  function symbol() external view returns (string memory) {
    return IPhoenixTracker(_otherAddr).symbol();
  }

  function totalSupply() external view returns (uint256) {
    return ended ? 0 : IPhoenixTracker(_otherAddr).totalSupply();
  }

  function balanceOf(address account) external view returns (uint256) {
    return ended ? 0 : IPhoenixTracker(_otherAddr).balanceOf(account);
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    return _transfer(msg.sender, to, amount);
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return IPhoenixTracker(_otherAddr).allowance(owner, spender);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private returns (bool) {
    return IPhoenixTracker(_otherAddr).approve(owner, spender, amount);
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    return _approve(msg.sender, spender, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {
    return _transfer(from, to, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private returns (bool) {
    require(!ended, "ended");
    IPhoenixTracker tracker = IPhoenixTracker(_otherAddr);
    uint256 transferAmount = amount;
    uint256 fees = 0;
    uint256 burnTokens = 0;
    bool success = true;

    if (from == _contractAddress) {
      from = _otherAddr;
    }

    if (to == _contractAddress) {
      to = _otherAddr;
    }

    if (from != NULL_ADDRESS && to != NULL_ADDRESS && !_liquid) {
      bool isBuy = from == _pair && _isUser(to);
      bool isSell = to == _pair && _isUser(from);
      bool isWhiteList = tracker.isWhiteList(from) || tracker.isWhiteList(to);
      bool isTax = !isWhiteList && (isBuy || isSell);

      if (isTax) {
        (fees, burnTokens) = tracker.syncFloorPrice(isBuy, amount);
        transferAmount = amount.sub(fees);
      }

      if (isSell && from != _otherAddr) {
        tracker.swapBack();
      }
    }

    success = tracker.transfer(msg.sender, from, to, transferAmount);
    emit Transfer(from, to, transferAmount);

    if (fees > 0) {
      success = tracker.transfer(from, from, _otherAddr, fees);
      emit Transfer(from, _otherAddr, fees);

      if (burnTokens > 0) {
        tracker.burn(_otherAddr, burnTokens);
        emit Transfer(_otherAddr, NULL_ADDRESS, burnTokens);
      }
    }

    return success;
  }

  function getPairs()
    external
    view
    returns (
      address pair,
      address[] memory pathBuy,
      address[] memory pathSell
    )
  {
    return (_pair, _pathBuy, _pathSell);
  }

  function endRound() external onlyOther {
    if (!ended) {
      _removeLiquidity(IERC20(_pair).balanceOf(_contractAddress));
      payable(_otherAddr).transfer(_contractAddress.balance);
      IPhoenixTracker(_otherAddr).clearTokens(_pair);
      ended = true;
    }
  }

  function addLiquidity(uint256 tokens) external payable onlyAuth {
    _addLiquidity(msg.value, tokens);
  }

  function _addLiquidity(uint256 bnb, uint256 tokens) private {
    _liquid = _approve(_contractAddress, address(_router), tokens);
    _router.addLiquidityETH{value: bnb}(_contractAddress, tokens, 0, 0, _contractAddress, block.timestamp);
    _liquid = false;
  }

  function _removeLiquidity(uint256 liquidity) private {
    _liquid = IERC20(_pair).approve(address(_router), liquidity);
    _router.removeLiquidityETH(_contractAddress, liquidity, 0, 0, _contractAddress, block.timestamp);
    _liquid = false;
  }
}