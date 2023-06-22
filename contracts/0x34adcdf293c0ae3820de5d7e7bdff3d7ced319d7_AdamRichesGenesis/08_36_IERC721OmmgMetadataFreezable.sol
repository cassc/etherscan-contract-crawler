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

/// @title IERC721OmmgMetadataFreezable
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves as an extension to {IERC721OmmgMetadata} and adds
/// functionality to freeze the metadata, effectively making it immutable.
interface IERC721OmmgMetadataFreezable {
    error MetadataIsFrozen();
    /// @notice Triggers when the metadata is frozen
    event MetadataFrozen();

    /// @notice Returns whether the metadata is frozen.
    /// @return frozen whether the metadata is frozen or not
    function metadataFrozen() external view returns (bool frozen);

    /// @notice Freezes the metadata to effectively turn it immutable. Emits {MetadataFrozen}.
    /// Fails if the metadata is already frozen.
    function freezeMetadata() external;
}