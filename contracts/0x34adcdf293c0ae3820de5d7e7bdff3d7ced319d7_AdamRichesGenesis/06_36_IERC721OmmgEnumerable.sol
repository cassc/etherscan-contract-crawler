// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

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

/// @title IERC721OmmgEnumerable
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves as an extension to {IERC721Enumerable} and adds
/// functionality to check if a token exists.
interface IERC721OmmgEnumerable is IERC721Enumerable {
    /// @notice Returns whether the token `tokenId` exists.
    /// @param tokenId the token id to check
    /// @return exists whether the token exists
    function exists(uint256 tokenId) external view returns (bool exists);
}