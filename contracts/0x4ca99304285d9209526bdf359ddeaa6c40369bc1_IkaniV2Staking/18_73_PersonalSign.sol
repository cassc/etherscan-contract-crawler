// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PersonalSign
 * @author Cyborg Labs, LLC
 *
 * @dev Helper function to verify messages signed with personal_sign.
 *
 *  IMPORTANT: Use cases which require users to sign some data (i.e. most signing use cases)
 *  should NOT use this. They should instead follow EIP-712, for security reasons.
 *
 *  NOTE: For our puroses, we assume that the message is hashed before being signed.
 *  The message length is therefore fixed at 32 bytes.
 *
 *  Signing example using ethers.js:
 *
 *  ```
 *    const encodedDataString = ethers.utils.defaultAbiCoder.encode(
 *      [
 *        // types
 *      ],
 *      [
 *        // values
 *      ],
 *    );
 *    const encodedData = Buffer.from(encodedDataString.slice(2), "hex");
 *    const innerDigestString = ethers.utils.keccak256(encodedData);
 *    const innerDigest = Buffer.from(innerDigestString.slice(2), "hex");
 *    const signature = await signer.signMessage(innerDigest);
 *  ```
 */
library PersonalSign {

  bytes constant private PERSONAL_SIGN_HEADER = "\x19Ethereum Signed Message:\n32";

  function isValidSignature(
    bytes32 messageDigest,
    bytes memory signature,
    address expectedSigner
  )
    internal
    pure
    returns (bool)
  {
    // Parse the signature into (v, r, s) components.
    require(
      signature.length == 65,
      "Bad signature length"
    );
    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Construct the digest hash which is signed within the `personal_sign` operation.
    bytes32 digest = keccak256(
      abi.encodePacked(
        PERSONAL_SIGN_HEADER,
        messageDigest
      )
    );

    // Check whether the recovered address is the required address.
    address recovered = ecrecover(digest, v, r, s);
    return recovered == expectedSigner;
  }

  function isValidSignature(
    bytes memory message,
    bytes memory signature,
    address expectedSigner
  )
    internal
    pure
    returns (bool)
  {
    return isValidSignature(
      keccak256(message),
      signature,
      expectedSigner
    );
  }
}