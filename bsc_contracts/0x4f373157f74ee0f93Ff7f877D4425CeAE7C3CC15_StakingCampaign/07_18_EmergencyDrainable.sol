// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @custom:security-contact [email protected]
abstract contract EmergencyDrainable is Ownable {
  using SafeERC20 for IERC20;


  // ==== State ==== //

  /**
   * @notice Jimizz BEP20 address
   */
  address public immutable jimizzAddress;

  /**
   * @notice Drain recipient address
   */
  address internal drainRecipient;


  // ==== Events ==== //

  /**
   * @notice Event emitted when owner drains native tokens
   */
  event Drained(uint256 amount);

  /**
   * @notice Event emitted when owner drains ERC tokens
   */
  event DrainedERC20(uint256 amount);

  /**
   * @notice Event emitted when owner changes address of the drain recipient
   */
  event DrainRecipientChanged(address oldRecipient, address newRecipient);


  // ==== Constructor ==== //

  /**
   * @dev constructor
   * @param _jimizzAddress The address of Jimizz BEP20
   */
  constructor(
    address _jimizzAddress
  ) {
    jimizzAddress = _jimizzAddress;
    drainRecipient = _msgSender();
  }


  // ==== Restricted methods ==== //

  /**
   * @notice Allows to recover ERC20 funds, except for Jimizz tokens
   */
  function drainERC20(address erc20Address)
    public
    virtual
    onlyOwner
  {
    require(
      erc20Address != jimizzAddress,
      "Jimizz funds cannot be drained"
    );

    IERC20 erc20 = IERC20(erc20Address);
    uint256 balance = erc20.balanceOf(address(this));
    require(
      balance > 0,
      "No token to drain"
    );

    erc20.safeTransfer(drainRecipient, balance);

    emit DrainedERC20(balance);
  }

  /**
   * @notice Allows to recover native funds
   */
  function drain()
    external
    virtual
    onlyOwner
  {
    uint256 balance = address(this).balance;
    require(
      balance > 0,
      "No native coin to drain"
    );

    (bool sent, ) = drainRecipient.call{value: balance}('');
    require(
      sent,
      "Unable to drain native coins"
    );

    emit Drained(balance);
  }

  /**
   * @notice Changes drain recipient's address
   */
  function changeDrainRecipient(address _drainRecipient)
    external
    onlyOwner
  {
    require(
      _drainRecipient != address(0x0),
      "Address is invalid"
    );

    address oldRecipient = drainRecipient;
    drainRecipient = _drainRecipient;
    emit DrainRecipientChanged(oldRecipient, drainRecipient);
  }
}