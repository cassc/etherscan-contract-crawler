// SPDX-License-Identifier: MIT
// Inspired by https://github.com/dharmaprotocol/0x-smart-contracts/blob/master/contracts/Spender.sol
pragma solidity ^0.8.21;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {ISpender} from './ISpender.sol';

/**
 * Proxy contract for transfering ERC20 tokens on behalf of a user so they only need to approve a single contract.
 *
 * Swap contracts are added with the TRANSFER_ROLE role which allows them to call transferFrom.
 */
contract Spender is AccessControl, ISpender {
  using SafeERC20 for IERC20;
  using Address for address;

  bytes32 public constant TRANSFER_ROLE = keccak256('TRANSFER_ROLE');

  constructor() {
    // Grant the contract deployer the default admin role: it will be able
    // to grant and revoke any roles
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function transferFrom(
    address token,
    address from,
    address to,
    uint256 amount
  ) external onlyRole(TRANSFER_ROLE) {
    // NOTE: This check doesn't work with Gnosis Safe multisig, etc.
    // require(from == tx.origin || from.isContract(), 'Invalid from address');

    IERC20(token).safeTransferFrom({from: from, to: to, value: amount});
  }

  // Admin withdraw in case of misplaced funds
  function withdraw(address token, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (token == address(0)) {
      // Send ETH
      payable(recipient).transfer(address(this).balance);

      return;
    }

    IERC20(token).safeTransfer(recipient, IERC20(token).balanceOf(address(this)));
  }
}