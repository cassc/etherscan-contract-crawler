// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// Thrown when hashed metadata does NOT match the expected hash.
/// @param expectedHash The hash expected by the `IMetaV1` contract.
/// @param actualHash The hash of the metadata seen by the `IMetaV1` contract.
error UnexpectedMetaHash(bytes32 expectedHash, bytes32 actualHash);

/// Thrown when some bytes are expected to be rain meta and are not.
/// @param unmeta the bytes that are not meta.
error NotRainMetaV1(bytes unmeta);

/// @dev Randomly generated magic number with first bytes oned out.
/// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
uint64 constant META_MAGIC_NUMBER_V1 = 0xff0a89c674ee7874;

/// @title IMetaV1
interface IMetaV1 {
    /// An onchain wrapper to carry arbitrary Rain metadata. Assigns the sender
    /// to the metadata so that tooling can easily drop/ignore data from unknown
    /// sources. As metadata is about something, the subject MUST be provided.
    /// @param sender The msg.sender.
    /// @param subject The entity that the metadata is about. MAY be the address
    /// of the emitting contract (as `uint256`) OR anything else. The
    /// interpretation of the subject is context specific, so will often be a
    /// hash of some data/thing that this metadata is about.
    /// @param meta Rain metadata V1 compliant metadata bytes.
    /// https://github.com/rainprotocol/specs/blob/main/metadata-v1.md
    event MetaV1(address sender, uint256 subject, bytes meta);
}