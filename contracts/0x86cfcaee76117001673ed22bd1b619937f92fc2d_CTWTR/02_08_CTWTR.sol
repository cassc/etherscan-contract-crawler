// SPDX-License-Identifier: UNLICENSED
/*
 *
 *                    https://cryptotwtr.com
 *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////@@@@@@@@@/@@@@@
 * @@@@@@@(//@@@@@@@@@@@@@@@@@@@@@@(/////////////////////@@@@@@
 * @@@@@@@/////#@@@@@@@@@@@@@@@@@@////////////////////%%///@@@@
 * @@@@@@@/////////@@@@@@@@@@@@@@///////////////////////%@@@@@@
 * @@@@@@@//////////////@@@@@@@@@/////////////////////@@@@@@@@@
 * @@@@@@@@@//////////////////////////////////////////@@@@@@@@@
 * @@@@@@@////////////////////////////////////////////@@@@@@@@@
 * @@@@@@@///////////////////////////////////////////@@@@@@@@@@
 * @@@@@@@@@/////////////////////////////////////////@@@@@@@@@@
 * @@@@@@@@@@@//////////////////////////////////////@@@@@@@@@@@
 * @@@@@@@@@@@////////////////////////////////////&@@@@@@@@@@@@
 * @@@@@@@@@@@@//////////////////////////////////@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@#/////////////////////////////@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@///////////////////////@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@%/////////////////////////@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@%///////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 *                    https://cryptotwtr.com
 *
 */

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./StatefulContract.sol";

error BuyTooBig(uint256 amount, uint256 limit);
error TransferForbidden(string msg);
error FreezeCannotBlockSafeAddress();
error SetupError(string msg);
error FreezeStateExist();

contract CTWTR is ERC20, ERC20Burnable, Ownable, StatefulContract {
  event AddressFrozen(address indexed addr);
  event AddressUnfrozen(address indexed addr);

  uint256 constant MAX_INT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  mapping(address => bool) private _isExcluded;
  address private liquidityPair;
  uint256 private disableFairLaunchAfter;

  // Mirror $TWTR shares (as of October 27th 2022)
  // 41,090,000,000 USD / 53.70 USD = 765,176,908 $TWTR
  // 1.75 ETH for (765176908 - 10%) = 688_659_218
  // 1 ETH of 688_659_218 is 393_519_553 CTWTR
  uint256 private _totalSupply = formatTokens(765_176_908);

  // 2.61378% of the supply max per buys during fair launch
  uint256 private _fairLaunchDuration = 3 hours;
  uint256 private _maxPerBuy = formatTokens(20_000_000);

  // Uniswap V3 Positions NFT-V1 (UNI-V3-POS)
  address private uniswapPositionsNFTAddress =
    address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  mapping(address => bool) private _dofoywktnl;

  constructor() ERC20("#CryptoTwitter", "CTWTR") {
    _isExcluded[owner()] = true;
    _isExcluded[uniswapPositionsNFTAddress] = true;
    _mint(owner(), _totalSupply);
  }

  function open(address _liquidityPair)
    external
    onlyOwner
    ensure(State.UNINITIALIZED)
  {
    if (_liquidityPair == address(0)) {
      revert SetupError("Liquidity pair invalid");
    }
    liquidityPair = _liquidityPair;
    disableFairLaunchAfter = block.timestamp + _fairLaunchDuration;
    upgradeState(State.FAIRLAUNCH);
  }

  // Can only manually freeze or unfreeze bots during the fair launch (2 hours)
  function setFreeze(address account, bool status)
    external
    onlyOwner
    ensure(State.FAIRLAUNCH)
  {
    if (_isExcluded[account] || account == liquidityPair) {
      revert FreezeCannotBlockSafeAddress();
    }

    if (_dofoywktnl[account] == status) {
      revert FreezeStateExist();
    }

    _dofoywktnl[account] = status;
    emit AddressFrozen(account);
  }

  function isFrozen(address account) external view returns (bool) {
    return _dofoywktnl[account];
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (to == address(0) || from == to) {
      return;
    }

    address _sender = _msgSender();

    if (
      _dofoywktnl[_sender] ||
      _dofoywktnl[from] ||
      _dofoywktnl[to] ||
      _dofoywktnl[tx.origin]
    ) {
      revert TransferForbidden("Blocked during fair launch");
    } else if (_getState() == State.UNINITIALIZED) {
      if (!_isExcluded[from] && !_isExcluded[to] && from != address(0)) {
        revert TransferForbidden(
          "Only excluded addresses may transfer at this point"
        );
      }
    } else if (
      _getState() == State.FAIRLAUNCH &&
      block.timestamp >= disableFairLaunchAfter
    ) {
      upgradeState(State.OPEN);
    }

    uint256 allowedAmount = _maxPerTx(from, to);
    if (amount >= allowedAmount) {
      revert BuyTooBig(amount, allowedAmount);
    }

    super._beforeTokenTransfer(from, to, amount);
  }

  function getState() external view returns (StatefulContract.State) {
    return _getState();
  }

  function _maxPerTx(address from, address to) private view returns (uint256) {
    if (
      _getState() <= State.FAIRLAUNCH &&
      from == liquidityPair &&
      !_isExcluded[from] &&
      !_isExcluded[to]
    ) {
      return _maxPerBuy;
    }

    return MAX_INT;
  }

  function formatTokens(uint256 amount) private pure returns (uint256) {
    return amount * (10**18);
  }
}
