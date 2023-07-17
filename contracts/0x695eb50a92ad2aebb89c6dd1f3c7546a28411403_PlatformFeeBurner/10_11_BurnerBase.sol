// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract BurnerBase is Ownable {
  using SafeERC20 for IERC20;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the address of receiver is updated.
  /// @param receiver The address of new receiver.
  event UpdateReceiver(address receiver);

  /// @notice Emitted when the keeper status of an account is updated.
  /// @param keeper The address of keeper updated.
  /// @param status The new keeper status.
  event UpdateKeeperStatus(address keeper, bool status);

  /*************
   * Variables *
   *************/

  /// @notice The address of token receiver.
  address public receiver;

  /// @notice Mapping from account address to keeper status.
  mapping(address => bool) public isKeeper;

  /*************
   * Modifiers *
   *************/

  modifier onlyKeeper() {
    require(isKeeper[msg.sender], "only keeper");
    _;
  }

  /***************
   * Constructor *
   ***************/

  constructor(address _receiver) {
    receiver = _receiver;
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /************************
   * Restricted Functions *
   ************************/

  /// @notice Update the address of receiver.
  /// @param _receiver The new address of receiver.
  function updateReceiver(address _receiver) external onlyOwner {
    receiver = _receiver;

    emit UpdateReceiver(_receiver);
  }

  /// @notice Update the keeper status.
  /// @param _keeper The address of keeper to update.
  /// @param _status The new status to update.
  function updateKeeperStatus(address _keeper, bool _status) external onlyOwner {
    isKeeper[_keeper] = _status;

    emit UpdateKeeperStatus(_keeper, _status);
  }

  /// @notice Withdraw dust assets in this contract.
  /// @param _token The address of token to withdraw.
  /// @param _recipient The address of token receiver.
  function withdrawFund(address _token, address _recipient) external onlyOwner {
    if (_token == address(0)) {
      (bool success, ) = _recipient.call{ value: address(this).balance }("");
      require(success, "withdraw ETH failed");
    } else {
      IERC20(_token).safeTransfer(_recipient, IERC20(_token).balanceOf(address(this)));
    }
  }
}