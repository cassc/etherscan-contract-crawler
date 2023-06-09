pragma solidity ^0.8.0;

contract SignatureParser {

  address public signer = 0x32f33EE03c50C3bFA057B5fd38aeb872A301c2cc;

  function _breakUpSignature (bytes memory signature)
    internal pure
  returns (uint8 v, bytes32 r, bytes32 s) {
      assembly {
          r := mload(add(signature, 32))
          s := mload(add(add(signature, 32), 32))
          v := mload(add(add(signature, 64), 1))
      }
  }

  function _signatureRecover (bytes32 hash, bytes memory signature)
    internal pure
  returns (address) {
     uint8 v;
     bytes32 r;
     bytes32 s;
     (v,r,s) = _breakUpSignature(signature);
     return ecrecover(hash, v, r, s);
  }



}