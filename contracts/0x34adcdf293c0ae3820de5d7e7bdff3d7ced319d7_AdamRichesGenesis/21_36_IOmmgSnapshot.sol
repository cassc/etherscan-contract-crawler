// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

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

/// @title ISnapshottable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for simple snapshots of all tokens
interface IOmmgSnapshot {
    enum TokenStatus {
        OWNED,
        BURNED
    }
    struct TokenInfo {
        uint256 tokenId;
        TokenStatus status;
        address owner;
    }

    /// @notice Returns an array of tuples [tokenId, tokenStatus, owner] with the
    /// current state of each minted token. A tokenStatus of 0 means it exists, 1 signals that
    /// the token has been burned.
    /// @return tokenStates the states of all minted tokens
    function snapshot() external view returns (TokenInfo[] memory tokenStates);
}