// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Ownable.sol";

error InvalidSignature();
error NoSigningKey();

contract EIP712Common is Ownable {
  using ECDSA for bytes32;

  // The key used to sign whitelist signatures.
  address signingKey = address(0);

  bytes32 public WHITELIST_DOMAIN_SEPARATOR;

  bytes32 public constant WHITELIST_TYPEHASH = keccak256("Minter(address wallet)");

  constructor() {
    WHITELIST_DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("WhitelistToken")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  function setSigningAddress(address _signingKey) external onlyOwner {
    signingKey = _signingKey;
  }

  modifier requiresAllowlist(bytes calldata signature) {
    if (signingKey == address(0)) revert NoSigningKey();

    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", WHITELIST_DOMAIN_SEPARATOR, keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender)))
    );

    address recoveredAddress = digest.recover(signature);
    if (recoveredAddress != signingKey) revert InvalidSignature();
    _;
  }
}