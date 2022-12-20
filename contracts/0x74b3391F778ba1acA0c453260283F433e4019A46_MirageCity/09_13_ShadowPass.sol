//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ShadowPassMain {

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct ShadowPass {
    uint shadowPassID;
    address to;
    Sig sig;
  }

  function validateShadowPass(ShadowPass calldata sp, address signer)
    internal pure returns (bool)
  {
    bytes32 h1 = keccak256(abi.encodePacked(sp.shadowPassID, sp.to));
    bytes32 h2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h1));
    return ecrecover(h2, sp.sig.v, sp.sig.r, sp.sig.s) == signer;
  }

}