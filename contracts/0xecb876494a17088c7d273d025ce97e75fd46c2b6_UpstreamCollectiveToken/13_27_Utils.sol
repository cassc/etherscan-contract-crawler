// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Utils {
  /**
  * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
  * @param _signedHash The signed hash
  * @param _signatures The concatenated signatures.
  * @param _index The index of the signature to recover.
  */
  function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
    uint8 v;
    bytes32 r;
    bytes32 s;
    // we jump 32 (0x20) as the first slot of bytes contains the length
    // we jump 65 (0x41) per signature
    // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
      s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
      v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
    }
    require(v == 27 || v == 28, "Utils: bad v value in signature");

    address recoveredAddress = ecrecover(_signedHash, v, r, s);
    require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
    return recoveredAddress;
  }
}