// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./abstracts/ShibaCardsAccessible.sol";
import "./abstracts/Dividends.sol";
import "./interfaces/ISharesDistributer.sol";

contract ShibaCardsSharesDistributer is
  ISharesDistributer,
  Dividends,
  ShibaCardsAccessible
{
  using SafeMath for uint256;

  mapping(address => uint256) private _sharesOf;

  /**
   * @dev Set total shares to 1000. 100 would mean smallest possible share is 1%, 1000 makes it 0.1%.
   */
  uint256 private constant TOTAL_SHARES = 1000;

  /**
   * @dev When constructing send all shares to owner
   * @dev owner may then transfer shares to somebody else
   */
  constructor() {
    _sharesOf[_msgSender()] = 1000;
  }

  /**
   * @dev Get shares by address
   */
  function getSharesOf(address account) public view override returns (uint256) {
    return _sharesOf[account];
  }

  /**
   * @dev Get total shares
   */
  function getTotalShares() public pure override returns (uint256) {
    return TOTAL_SHARES;
  }

  /**
   * @dev Everyone who owns shares should be able to move their own shares.
   */
  function transferShares(address to, uint256 shares) external {
    _transferShares(_msgSender(), to, shares);
  }

  /**
   * @dev Move shares from one to another.
   */
  function moveShares(
    address from,
    address to,
    uint256 shares
  ) external override onlyAdmin {
    _transferShares(from, to, shares);
  }

  /**
   * @dev Move shares from one to another.
   */
  function _transferShares(
    address from,
    address to,
    uint256 shares
  ) internal {
    require(_sharesOf[from] >= shares, "Insufficient shares");
    _sharesOf[from] -= shares;
    _sharesOf[to] += shares;
    _correctPointsForTransfer(from, to, shares);
  }

  /**
   * @dev Distribute money
   */
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