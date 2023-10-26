//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {IDepositContract} from "../interfaces/IDepositContract.sol";

/// @title  A contract for holding a eth2 validator withrawal pubkey
/// @author @chimeraDefi
/// @notice A contract for holding a eth2 validator withrawal pubkey
/// @dev Downstream contract needs to implement who can set the withdrawal address and set it
contract ETH2DepositWithdrawalCredentials {
  uint internal constant _depositAmount = 32 ether;
  IDepositContract public immutable depositContract;
  bytes public curr_withdrawal_pubkey; // Pubkey for ETH 2.0 withdrawal creds

  event WithdrawalCredentialSet(bytes _withdrawalCredential);

  constructor(address _dc) {
    depositContract = IDepositContract(_dc);
  }

  /// @notice A more streamlined variant of batch deposit for use with preset withdrawal addresses
  ///         Submit index-matching arrays that form Phase 0 DepositData objects.
  ///         Will create a deposit transaction per index of the arrays submitted.
  ///
  /// @param pubkeys - An array of BLS12-381 public keys.
  /// @param signatures - An array of BLS12-381 signatures.
  /// @param depositDataRoots - An array of the SHA-256 hash of the SSZ-encoded DepositData object.
  function _batchDeposit(
      bytes[] calldata pubkeys,
      bytes[] calldata signatures,
      bytes32[] calldata depositDataRoots
  ) internal {
    // optimizations https://ethereum.stackexchange.com/questions/113221/what-is-the-purpose-of-unchecked-in-solidity
    // https://medium.com/@bloqarl/solidity-gas-optimization-tips-with-assembly-you-havent-heard-yet-1381c77ff078
    // 30m gas / block roughly, say 10m max used so 100 validators a batch max 
    // each deposit call costs roughly 128k https://etherscan.io/tx/0xa2acf6e6bde99b532125cc8026cd88eea345f296968ce732556945ab4705d03e
    uint i = pubkeys.length;
    uint _amt = _depositAmount;
    bytes memory wpk = curr_withdrawal_pubkey;

    while (i > 0) {
      unchecked {
      // While loop check prevents underflow.
      // --i is cheaper than i--
      // reverse while loop cheapest compared to while or for 
      // Since we set the upper loop bound to the arr len, we decr 1st to not hit out of bounds
        --i;

        depositContract.deposit{value: _amt}(
          pubkeys[i],
          wpk,
          signatures[i],
          depositDataRoots[i]
        );
      }
    }
  }

  /// @notice sets curr_withdrawal_pubkey to be used when deploying validators
  function _setWithdrawalCredential(bytes memory _new_withdrawal_pubkey) internal {
    curr_withdrawal_pubkey = _new_withdrawal_pubkey;

    emit WithdrawalCredentialSet(_new_withdrawal_pubkey);
  }
}