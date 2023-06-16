// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Signature {
  function splitSignature(bytes memory sig)
      public pure returns (bytes32 r, bytes32 s, uint8 v)
  {
      require(sig.length == 65, "invalid signature length");

      assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := byte(0, mload(add(sig, 96)))
      }

      if (v < 27) v += 27;
  }

  function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
      return _isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s);
  }

  function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
      internal pure returns (bool)
  {
      return ecrecover(messageHash, v, r, s) == _address;
  }

  function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
      internal pure returns (bool)
  {
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      return _isSigned(_address, keccak256(abi.encodePacked(prefix, messageHash)), v, r, s);
  }
  
}