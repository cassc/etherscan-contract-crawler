// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../EIP712/UpgradeableEIP712.sol";
import { ECDSA } from "oz460/utils/cryptography/ECDSA.sol";

bytes constant Permit_typeString = "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)";
bytes32 constant Permit_typeHash = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
uint256 constant Permit_typeHash_ptr = 0x0;
uint256 constant Permit_owner_ptr = 0x20;
uint256 constant Permit_nonce_ptr = 0x80;
uint256 constant Permit_deadline_ptr = 0xa0;
uint256 constant Permit_owner_cdPtr = 0x04;
uint256 constant Permit_v_cdPtr = 0x84;
uint256 constant Permit_signature_length = 0x60;
uint256 constant Permit_calldata_params_length = 0x60;
uint256 constant Permit_length = 0xc0;

uint256 constant ECRecover_precompile = 0x01;
uint256 constant ECRecover_digest_ptr = 0x0;
uint256 constant ECRecover_v_ptr = 0x20;
uint256 constant ECRecover_calldata_length = 0x80;

contract SignatureVerification is UpgradeableEIP712 {
  /*//////////////////////////////////////////////////////////////
                             Constructor
  //////////////////////////////////////////////////////////////*/

  constructor(
    address _proxyContract,
    string memory _name,
    string memory _version
  ) UpgradeableEIP712(_proxyContract, _name, _version) {
    if (Permit_typeHash != keccak256(Permit_typeString)) {
      revert InvalidTypeHash();
    }
  }

  /*//////////////////////////////////////////////////////////////
                               Permit
  //////////////////////////////////////////////////////////////*/

  function _digestPermit(uint256 nonce, uint256 deadline) internal view returns (bytes32 digest) {
    bytes32 domainSeparator = getDomainSeparator();
    assembly {
      mstore(Permit_typeHash_ptr, Permit_typeHash)
      calldatacopy(Permit_owner_ptr, Permit_owner_cdPtr, Permit_calldata_params_length)
      mstore(Permit_nonce_ptr, nonce)
      mstore(Permit_deadline_ptr, deadline)
      let permitHash := keccak256(Permit_typeHash_ptr, Permit_length)
      mstore(0, EIP712Signature_prefix)
      mstore(EIP712Signature_domainSeparator_ptr, domainSeparator)
      mstore(EIP712Signature_digest_ptr, permitHash)
      digest := keccak256(0, EIP712Signature_length)
    }
  }

  function _verifyPermitSignature(
    address owner,
    uint256 nonce,
    uint256 deadline
  ) internal view RestoreFirstTwoUnreservedSlots RestoreFreeMemoryPointer RestoreZeroSlot {
    bytes32 digest = _digestPermit(nonce, deadline);
    bool validSignature;
    assembly {
      mstore(ECRecover_digest_ptr, digest)
      // Copy v, r, s from calldata
      calldatacopy(ECRecover_v_ptr, Permit_v_cdPtr, Permit_signature_length)
      // Call ecrecover precompile to validate signature
      let success := staticcall(
        gas(),
        ECRecover_precompile, // ecrecover precompile
        ECRecover_digest_ptr,
        ECRecover_calldata_length,
        0x0,
        0x20
      )
      validSignature := and(
        success, // call succeeded
        and(
          gt(owner, 0), // owner != 0
          eq(owner, mload(0)) // owner == recoveredAddress
        )
      )
    }
    if (!validSignature) {
      revert InvalidSigner();
    }
  }
}