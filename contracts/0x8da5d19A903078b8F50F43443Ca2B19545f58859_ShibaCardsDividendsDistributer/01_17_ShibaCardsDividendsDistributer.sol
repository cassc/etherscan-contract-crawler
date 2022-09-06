// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./abstracts/ShibaCardsAccessible.sol";
import "./abstracts/Dividends.sol";
import "./interfaces/IDividendsDistributer.sol";

contract ShibaCardsDividendsDistributer is
  IDividendsDistributer,
  Dividends,
  ShibaCardsAccessible
{
  using SafeMath for uint256;
  using SafeCast for int256;
  
  uint256 private _totalShares;
  mapping(address => uint256) private _sharesOf;
  
  function getSharesOf(address account) public view override returns (uint256) {
    return _sharesOf[account];
  }

  function getTotalShares() public view override returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Add shares
   */
  function addShares(address to, uint256 shares)
    external
    override
    onlyWhitelisted
  {
    _totalShares += shares;
    _sharesOf[to] += shares;
    _correctPoints(to, -int256(shares));
    emit SharesAdded(to, shares);
  }

  /**
   * @dev Remove shares
   */
  function removeShares(address from, uint256 shares)
    external
    override
    onlyWhitelisted
  {
    require(shares > 0, "No shares given");
    
    if (_totalShares > 0) {
      _totalShares -= shares;
    }
    
    if (_sharesOf[from] > 0) {
      _sharesOf[from] -= shares;
    }
    
    _correctPoints(from, int256(shares));
    emit SharesRemoved(from, shares);
  }

  /**
   * @dev Move shares from one to another
   */
  function transferShares(
    address from,
    address to,
    uint256 shares
  ) external override onlyWhitelisted {
    require(_sharesOf[from] >= shares, "Insufficient shares");
    _sharesOf[from] -= shares;
    _sharesOf[to] += shares;
    _correctPointsForTransfer(from, to, shares);
    emit SharesTransferred(from, to, shares);
  }

  function distribute(uint256 amount) public override onlyWhitelisted {
    _distributeDividends(amount);
  }

  /**
   * @dev Display claimable amount
   */
  function claimable() external view override returns (uint256) {
    return _withdrawableDividendsOf(_msgSender());
  }

  /**
   * @dev Prepares claiming
   */
  function prepareClaim(address account)
    external
    override
    onlyWhitelisted
    returns (uint256)
  {
    return _prepareCollect(account);
  }
}