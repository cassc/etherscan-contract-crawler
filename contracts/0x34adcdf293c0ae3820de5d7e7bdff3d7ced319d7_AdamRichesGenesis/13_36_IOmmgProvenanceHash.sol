// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgProvenanceHash
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a freezable provenance hash, to enable full trust that
/// the metadata of the underlying token is not predetermined or tampered with.
interface IOmmgProvenanceHash {
    /// @notice Triggers when an attempt is made to change the provenance
    /// hash after it has been frozen
    error ProvenanceHashIsFrozen();
    /// @notice Triggers when the provenance hash is set to a new value.
    /// @param provenanceHash the new provenance hash.
    event ProvenanceHashSet(string indexed provenanceHash);
    /// @notice Triggers when the provenance hash is frozen.
    event ProvenanceHashFrozen();

    /// @notice Returns the current provenance hash. The idea is for this to be
    /// the proof that the order of token metada has not been tampered with and
    /// that it has not been predetermined.
    /// @return provenanceHash the provenance hash
    function provenanceHash()
        external
        view
        returns (string memory provenanceHash);

    /// @notice Returns a boolean value indicating whether the provenance hash
    /// has been frozen or not. A frozen provenance hash is immutable.
    /// @return isFrozen whether it is frozen or not
    function provenanceFrozen() external view returns (bool isFrozen);

    /// @notice Updates the provenance hash to the new value `provenanceHash`.
    /// Also triggers the event {ProvenanceHashSet} and reverts if the provenance
    /// hash has already been frozen.
    function setProvenanceHash(string memory provenanceHash) external;

    /// @notice freezes the provenance hash and thus makes it immutable.
    /// Triggers a {ProvenanceHashFrozen} event and reverts if the hash is already frozen.
    function freezeProvenance() external;
}