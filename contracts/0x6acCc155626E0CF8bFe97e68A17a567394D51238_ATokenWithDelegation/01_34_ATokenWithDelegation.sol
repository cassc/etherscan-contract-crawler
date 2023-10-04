// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {BaseDelegation} from 'aave-token-v3/BaseDelegation.sol';
import {AToken} from './AToken.sol';

/**
 * @author BGD Labs
 * @notice contract that gives a tokens the delegation functionality. For now should only be used for AAVE aToken
 * @dev uint sizes are used taken into account that is tailored for AAVE token. In this AToken child we only update
        delegation balances. Balances amount is taken care of by AToken contract
 */
contract ATokenWithDelegation is AToken, BaseDelegation {
  struct ATokenDelegationState {
    uint72 delegatedPropositionBalance;
    uint72 delegatedVotingBalance;
  }

  mapping(address => ATokenDelegationState) internal _delegatedState;

  constructor(IPool pool) AToken(pool) {}

  function _getDomainSeparator() internal view override returns (bytes32) {
    return DOMAIN_SEPARATOR();
  }

  function _getDelegationState(
    address user
  ) internal view override returns (DelegationState memory) {
    return
      DelegationState({
        delegatedPropositionBalance: _delegatedState[user].delegatedPropositionBalance,
        delegatedVotingBalance: _delegatedState[user].delegatedVotingBalance,
        delegationMode: _userState[user].delegationMode
      });
  }

  function _getBalance(address user) internal view override returns (uint256) {
    return _userState[user].balance;
  }

  function _incrementNonces(address user) internal override returns (uint256) {
    unchecked {
      // Does not make sense to check because it's not realistic to reach uint256.max in nonce
      return _nonces[user]++;
    }
  }

  function _setDelegationState(
    address user,
    DelegationState memory delegationState
  ) internal override {
    _userState[user].delegationMode = delegationState.delegationMode;
    _delegatedState[user].delegatedPropositionBalance = delegationState.delegatedPropositionBalance;
    _delegatedState[user].delegatedVotingBalance = delegationState.delegatedVotingBalance;
  }

  /**
   * @notice Overrides the parent _transfer to force validated transfer() and delegation balance transfers
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   */
  function _transfer(address from, address to, uint256 amount, bool validate) internal override {
    _delegationChangeOnTransfer(from, to, _getBalance(from), _getBalance(to), amount);
    super._transfer(from, to, amount, validate);
  }
}