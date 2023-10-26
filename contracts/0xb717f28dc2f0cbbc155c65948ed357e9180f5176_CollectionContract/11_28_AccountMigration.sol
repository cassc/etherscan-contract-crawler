// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-solc-8/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts-solc-8/utils/Strings.sol";

/**
 * @notice Checks for a valid signature authorizing the migration of an account to a new address.
 * @dev This is shared by both the NFT contracts and FNDNFTMarket, and the same signature authorizes both.
 */
library AccountMigration {
  using SignatureChecker for address;
  using Strings for uint256;

  // From https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function _toAsciiString(address x) private pure returns (string memory) {
    bytes memory s = new bytes(42);
    s[0] = "0";
    s[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i + 2] = _char(hi);
      s[2 * i + 3] = _char(lo);
    }
    return string(s);
  }

  function _char(bytes1 b) private pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/cryptography/ECDSA.sol
  // Modified to accept messages (instead of the message hash)
  function _toEthSignedMessage(bytes memory message) private pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", message.length.toString(), message));
  }

  /**
   * @dev Confirms the msg.sender is a Foundation operator and that the signature provided is valid.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function requireAuthorizedAccountMigration(
    address originalAddress,
    address newAddress,
    bytes memory signature
  ) internal view {
    require(originalAddress != newAddress, "AccountMigration: Cannot migrate to the same account");
    bytes32 hash = _toEthSignedMessage(
      abi.encodePacked("I authorize Foundation to migrate my account to ", _toAsciiString(newAddress))
    );
    require(
      originalAddress.isValidSignatureNow(hash, signature),
      "AccountMigration: Signature must be from the original account"
    );
  }
}