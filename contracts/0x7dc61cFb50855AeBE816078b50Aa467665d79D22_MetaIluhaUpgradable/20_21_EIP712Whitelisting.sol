//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {
  ECDSAUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {
  Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
  AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract EIP712Whitelisting is Initializable, AccessControlUpgradeable {
  using ECDSAUpgradeable for bytes32;

  // The key used to sign whitelist signatures.
  // We will check to ensure that the key that signed the signature
  // is this one that we expect.
  address whitelistSigningKey;

  // Domain Separator is the EIP-712 defined structure that defines what contract
  // and chain these signatures can be used for.  This ensures people can't take
  // a signature used to mint on one contract and use it for another, or a signature
  // from testnet to replay on mainnet.
  // It has to be created in the constructor so we can dynamically grab the chainId.
  bytes32 public DOMAIN_SEPARATOR;
  bytes32 public MINTER_TYPEHASH;

  function __EIP712Whitelisting_init(
    address newSigningKey,
    string memory name_,
    string memory version_
  ) internal onlyInitializing {
    __AccessControl_init();

    whitelistSigningKey = newSigningKey;
    MINTER_TYPEHASH = keccak256("Minter(address wallet)");
    // This should match whats in the client side whitelist signing code
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        // This should match the domain you set in your client side signing.
        keccak256(bytes(name_)),
        keccak256(bytes(version_)),
        block.chainid,
        address(this)
      )
    );
  }

  function setWhitelistSigningAddress(
    address newSigningKey
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    whitelistSigningKey = newSigningKey;
  }

  modifier requiresWhitelist(bytes calldata signature) {
    require(
      whitelistSigningKey != address(0),
      "EIP712Whitelisting: whitelist not enabled"
    );
    // Verify EIP-712 signature by recreating the data structure
    // that we signed on the client side, and then using that to recover
    // the address that signed the signature for this data.
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
      )
    );
    // Use the recover method to see what address was used to create
    // the signature on this data.
    // Note that if the digest doesn't exactly match what was signed we'll
    // get a random recovered address.
    address recoveredAddress = digest.recover(signature);
    require(
      recoveredAddress == whitelistSigningKey,
      "EIP712Whitelisting: Invalid Signature"
    );
    _;
  }
}