//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library CosmicverseVoucher {

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct Voucher {
    uint voucherId;
    address to;
    uint maxMint;
    Sig sig;
  }

  function validateVoucher(Voucher calldata v, address signer)
    internal pure returns (bool)
  {
    bytes32 h1 = keccak256(abi.encodePacked(v.voucherId, v.to, v.maxMint));
    bytes32 h2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h1));
    return ecrecover(h2, v.sig.v, v.sig.r, v.sig.s) == signer;
  }

}