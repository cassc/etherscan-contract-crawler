// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {RoundData} from "./libraries/AppStorage.sol";

abstract contract BulletinSigning {
  string internal constant VERSION = "v0.0.1";

  bytes32 internal constant ROUNDATA_TYPEHASH = keccak256(
    "RoundData(uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound)"
  );
  bytes32 internal constant NAMEHASH = keccak256("CuicaFacet");
  bytes32 internal constant VERSIONHASH = keccak256(abi.encode(VERSION));
  bytes32 internal constant TYPEHASH =
    keccak256("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)");

  /// @notice Returns the struct hash of `latestRoundData`.
  function getStructHashRoundData(RoundData memory lastRoundData) public pure returns (bytes32) {
    return keccak256(
      abi.encode(
        ROUNDATA_TYPEHASH,
        lastRoundData.roundId,
        lastRoundData.answer,
        lastRoundData.startedAt,
        lastRoundData.updatedAt,
        lastRoundData.answeredInRound
      )
    );
  }

  /**
   * @notice Returns the struct hash for `latestRoundData`.
   */
  function getHashTypedDataV4Digest(bytes32 structHash) public view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", _getDomainSeparator(), structHash));
  }

  /**
   * @dev Returns the domainSeparator for "CuicaFacet".
   *
   * Requirement:
   * - Must return always domain for Gnosis chain.
   */
  function _getDomainSeparator() internal view virtual returns (bytes32);
}