pragma solidity ^0.7.0;

interface TonUtils {
    struct TonAddress {
        int8 workchain;
        bytes32 address_hash;
    }
    struct TonTxID {
        TonAddress address_;
        bytes32 tx_hash;
        uint64 lt;
    }

  struct SwapData {
        address receiver;
        uint64 amount;
        TonTxID tx;
  }
  struct Signature {
        address signer;
        bytes signature;
  }

}