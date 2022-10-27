// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelistable is Ownable {
  using ECDSA for bytes32;

  address whitelistSigningKey = address(0);

  bytes32 public DOMAIN_SEPARATOR;

  bytes32 public constant MINTER_TYPEHASH = keccak256("Minter(address wallet)");

  constructor(address signerPubKey) {
    whitelistSigningKey = signerPubKey;

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),

        keccak256(bytes("WhitelistMint")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  function setWhitelistSigningAddress(address newSigningKey) public onlyOwner {
    whitelistSigningKey = newSigningKey;
  }

  modifier requiresWhitelist(bytes calldata signature) {
    require(whitelistSigningKey != address(0), "whitelist not enabled");

    bytes32 digest = keccak256(
        abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(MINTER_TYPEHASH, _msgSender()))
        )
    );

    address recoveredAddress = digest.recover(signature);
    require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
    _;
  }
}