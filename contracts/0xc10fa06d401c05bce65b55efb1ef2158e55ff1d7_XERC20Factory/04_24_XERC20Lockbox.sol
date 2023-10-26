// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from '../interfaces/IXERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {IXERC20Lockbox} from '../interfaces/IXERC20Lockbox.sol';

contract XERC20Lockbox is IXERC20Lockbox {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  /**
   * @notice The XERC20 token of this contract
   */
  IXERC20 public immutable XERC20;

  /**
   * @notice The ERC20 token of this contract
   */
  IERC20 public immutable ERC20;

  /**
   * @notice Whether the ERC20 token is the native gas token of this chain
   */

  bool public immutable IS_NATIVE;

  /**
   * @notice Constructor
   *
   * @param _xerc20 The address of the XERC20 contract
   * @param _erc20 The address of the ERC20 contract
   */

  constructor(address _xerc20, address _erc20, bool _isNative) {
    XERC20 = IXERC20(_xerc20);
    ERC20 = IERC20(_erc20);
    IS_NATIVE = _isNative;
  }

  /**
   * @notice Deposit native tokens into the lockbox
   */

  function depositNative() public payable {
    if (!IS_NATIVE) revert IXERC20Lockbox_NotNative();

    _deposit(msg.sender, msg.value);
  }

  /**
   * @notice Deposit ERC20 tokens into the lockbox
   *
   * @param _amount The amount of tokens to deposit
   */

  function deposit(uint256 _amount) external {
    if (IS_NATIVE) revert IXERC20Lockbox_Native();

    _deposit(msg.sender, _amount);
  }

  /**
   * @notice Deposit ERC20 tokens into the lockbox, and send the XERC20 to a user
   *
   * @param _to The user to send the XERC20 to
   * @param _amount The amount of tokens to deposit
   */

  function depositTo(address _to, uint256 _amount) external {
    if (IS_NATIVE) revert IXERC20Lockbox_Native();

    _deposit(_to, _amount);
  }

  /**
   * @notice Deposit the native asset into the lockbox, and send the XERC20 to a user
   *
   * @param _to The user to send the XERC20 to
   */

  function depositNativeTo(address _to) public payable {
    if (!IS_NATIVE) revert IXERC20Lockbox_NotNative();

    _deposit(_to, msg.value);
  }

  /**
   * @notice Withdraw ERC20 tokens from the lockbox
   *
   * @param _amount The amount of tokens to withdraw
   */

  function withdraw(uint256 _amount) external {
    _withdraw(msg.sender, _amount);
  }

  /**
   * @notice Withdraw tokens from the lockbox
   *
   * @param _to The user to withdraw to
   * @param _amount The amount of tokens to withdraw
   */

  function withdrawTo(address _to, uint256 _amount) external {
    _withdraw(_to, _amount);
  }

  /**
   * @notice Withdraw tokens from the lockbox
   *
   * @param _to The user to withdraw to
   * @param _amount The amount of tokens to withdraw
   */

  function _withdraw(address _to, uint256 _amount) internal {
    emit Withdraw(_to, _amount);

    XERC20.burn(msg.sender, _amount);

    if (IS_NATIVE) {
      (bool _success,) = payable(_to).call{value: _amount}('');
      if (!_success) revert IXERC20Lockbox_WithdrawFailed();
    } else {
      ERC20.safeTransfer(_to, _amount);
    }
  }

  /**
   * @notice Deposit tokens into the lockbox
   *
   * @param _to The address to send the XERC20 to
   * @param _amount The amount of tokens to deposit
   */

  function _deposit(address _to, uint256 _amount) internal {
    if (!IS_NATIVE) {
      ERC20.safeTransferFrom(msg.sender, address(this), _amount);
    }

    XERC20.mint(_to, _amount);
    emit Deposit(_to, _amount);
  }

  receive() external payable {
    depositNative();
  }
}