// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./abstracts/ShibaCardsAccessible.sol";
import "./abstracts/ShibaCardsSharesDistributable.sol";
import "./abstracts/ShibaCardsDividendsDistributable.sol";
import "./abstracts/ShibaCardsWithdrawable.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IDistributer.sol";

contract ShibaCardsBank is
  IBank,
  ShibaCardsAccessible,
  ShibaCardsDividendsDistributable,
  ShibaCardsSharesDistributable,
  ShibaCardsWithdrawable
{
  using SafeMath for uint256;
  ERC20Burnable public erc20;

  uint256 public constant BURN = 5;
  uint256 public constant DISTRIBUTE = 20;
  uint256 public constant TRANSFER_FEES = 7;
  uint256 public constant TRANSFER_DISTRIBUTION = 2;
  uint256 public constant TRANSFER_BURN = 1;

  function setERC20(ERC20Burnable _erc20) public onlyAdmin {
    erc20 = _erc20;
  }

  modifier requireERC20() {
    require(address(erc20) != address(0), "No ERC20 defined.");
    _;
  }

  /**
   * @dev Pay in ERC20, burn 5%
   */
  function makePayment(address from, uint256 amount)
    public
    override
    requireERC20
    onlyWhitelisted
  {
    SafeERC20.safeTransferFrom(erc20, from, address(this), amount);
    _burn(amount.div(100).mul(BURN));
  }

  /**
   * @dev Transfer in ERC20, burn 5%
   */
  function transfer(
    address from,
    address to,
    uint256 amount
  ) public override requireERC20 onlyWhitelisted {
    uint256 burn = amount.div(100).mul(TRANSFER_BURN);
    uint256 fees = amount.div(100).mul(TRANSFER_FEES);
    uint256 distribution = amount.div(100).mul(TRANSFER_DISTRIBUTION);

    SafeERC20.safeTransferFrom(erc20, from, address(this), burn.add(fees).add(distribution));
    SafeERC20.safeTransferFrom(erc20, from, to, amount.sub(burn).sub(fees).sub(distribution));

    sharesDistributer.distribute(fees);
    dividendsDistributer.distribute(distribution);

    _burn(burn);
  }

  function _burn(uint256 amount) internal {
    erc20.burn(amount);
    emit ERC20Burned(amount);
  }

  /**
   * @dev Send ERC20
   */
  function _send(address to, uint256 amount) internal requireERC20 {
    SafeERC20.safeTransfer(erc20, to, amount);
  }

  function distribute(uint256 amount)
    public
    override
    onlyWhitelisted
  {
    require(amount > 0, "Amount must be greater than 0.");
    uint256 total = 100;
    dividendsDistributer.distribute(amount.div(100).mul(DISTRIBUTE));
    sharesDistributer.distribute(amount.div(100).mul(total.sub(DISTRIBUTE).sub(BURN)));
  }

  /**
   * @dev Withdraw collaborator shares
   */
  function claimShares() external override {
    uint256 shares = sharesDistributer.prepareClaim(_msgSender());
    require(shares > 0, "No shares");
    _send(_msgSender(), shares);
    emit SharesClaimed(_msgSender(), shares);
  }

  /**
   * @dev Claim your dividends
   */
  function claimDividends() external override {
    uint256 shares = dividendsDistributer.prepareClaim(_msgSender());
    require(shares > 0, "No shares");
    _send(_msgSender(), shares);
    emit DividendsClaimed(_msgSender(), shares);
  }
}