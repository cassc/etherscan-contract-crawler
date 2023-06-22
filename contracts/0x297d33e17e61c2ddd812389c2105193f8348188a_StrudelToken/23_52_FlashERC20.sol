// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./IBorrower.sol";
import "./ILender.sol";

// inspired by https://github.com/Austin-Williams/flash-mintable-tokens/blob/master/FlashERC20/FlashERC20.sol
contract FlashERC20 is
  Initializable,
  ContextUpgradeSafe,
  ERC20UpgradeSafe,
  ILender,
  OwnableUpgradeSafe
{
  uint256 constant BTC_CAP = 21 * 10**24;
  uint256 constant FEE_FACTOR = 100;

  // used for reentrance guard
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  event FlashMint(address indexed src, uint256 wad, bytes32 data, uint256 fee);

  // working memory
  uint256 private _status;
  // Dev fund
  uint256 public devFundDivRate;

  function __Flash_init(string memory name, string memory symbol) internal initializer {
    devFundDivRate = 17;
    _status = _NOT_ENTERED;
    __ERC20_init(name, symbol);
    __Ownable_init();
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `_lock_` function from another `_lock_`
   * function is not supported. It is possible to prevent this from happening
   * by making the `_lock_` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier lock() {
    // On the first call to _lock_, _notEntered will be true
    require(_status != _ENTERED, "ERR_REENTRY");

    // Any calls to _lock_ after this point will fail
    _status = _ENTERED;
    _;
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  // Allows anyone to mint tokens as long as it gets burned by the end of the transaction.
  function flashMint(uint256 amount, bytes32 data) external override lock {
    // do not exceed cap
    require(totalSupply().add(amount) <= BTC_CAP, "can not borrow more than BTC cap");

    // mint tokens
    _mint(msg.sender, amount);

    // hand control to borrower
    IBorrower(msg.sender).executeOnFlashMint(amount, data);

    uint256 fee = amount.div(devFundDivRate.mul(FEE_FACTOR));

    // burn tokens
    _burn(msg.sender, amount.add(fee)); // reverts if `msg.sender` does not have enough
    _mint(owner(), fee);

    emit FlashMint(msg.sender, amount, data, fee);
  }

  // governance function
  function setDevFundDivRate(uint256 _devFundDivRate) external onlyOwner {
    require(_devFundDivRate > 0, "!devFundDivRate-0");
    devFundDivRate = _devFundDivRate;
  }
}