// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

// solhint-disable avoid-low-level-calls

/**
 * @title The transfer helpers library
 * @author Plug Exchange
 * @notice Handles token transfers, approvals and ethereum transfers for protocol
 */
library TransferHelpers {
  /**
   * @dev Safe approve an ERC20 token
   * @param token an ERC20 token
   * @param to The spender address
   * @param value The value that will be approve
   */
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: approval failed');
  }

  /**
   * @dev Token approvals must required
   * @param target The ERC20 token address
   * @param sender The sender wallet address
   * @param recipient The receiver wallet Address
   * @param amount The number of tokens to transfer
   */
  function safeTransferFrom(
    address target,
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    (bool success, ) = target.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount));
    require(success, 'TransferHelper: transfer failed');
  }

  /**
   * @notice Transfer any ERC20 token
   * @param target The target contract address
   * @param to The receiver wallet address
   * @param amount The number of tokens to transfer
   */
  function safeTransfer(
    address target,
    address to,
    uint256 amount
  ) internal {
    (bool success, ) = target.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
    require(success, 'TransferHelper: transfer failed');
  }

  /**
   * @notice Transfer ETH
   * @param to The receiver wallet address
   * @param value The ETH to transfer
   */
  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: uint128(value)}(new bytes(0));
    require(success, 'TransferHelper: transfer failed');
  }
}