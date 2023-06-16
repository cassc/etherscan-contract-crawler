pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is part of pjf project (https://pjf.one).
 * Developed by Jagat Token (jagatoken.com).
 *
 */

contract SigVerifier {
    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

  function sigPrefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }

    
  function _isSigner(address account, bytes32 message, Sig memory sig)
    internal
    pure
    returns (bool)
  {
    return ecrecover(message, sig.v, sig.r, sig.s) == account;
  }
}