// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

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

/// @title IERC721OmmgMetadata
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves as an extension to {IERC721Metadata} and adds
/// functionality to reveal tokens as well as add more logic to the token uri.
interface IERC721OmmgMetadata is IERC721Metadata {
    /// @notice Triggers when the base uri is updated.
    /// @param baseURI the new base uri
    event SetBaseUri(string indexed baseURI);

    /// @notice Triggers when the URI for a token is overridden.
    /// @param tokenId the token where the URI is overridden
    /// @param fullOverride fullOverride whether the override overrides the base URI or is appended
    /// @param tokenRevealedOverride whether the token should be individually revealed
    /// @param tokenURI the override token URI
    event SetTokenUri(
        uint256 indexed tokenId,
        bool fullOverride,
        bool tokenRevealedOverride,
        string indexed tokenURI
    );
    /// @notice Triggers when the unrevealed token uri is updated.
    /// @param unrevealedTokenURI the new unrevealed token uri
    event UnrevealedTokenUriSet(string indexed unrevealedTokenURI);

    /// @notice Triggers when the collection is revealed.
    event Revealed();

    /// @notice Triggers when a singular token is revealed.
    /// @param tokenId the token which is revealed
    event TokenRevealed(uint256 indexed tokenId);

    /// @notice Returns whether the collection as a whole is revealed.
    /// @param revealed whether the collection is revealed
    function revealed() external view returns (bool revealed);

    /// @notice Reveals the collection. Emits {Revealed}.
    function reveal() external;

    /// @notice Reveals an individual token. Fails if the token does not exist.
    /// Emits {TokenRevealed}.
    /// @param tokenId the id of the revealed token
    function revealToken(uint256 tokenId) external;

    /// @notice Overrides the token URI for an individual token and optionally sets whether the base uri
    /// should be overridden too, and whether the token should be revealed individually. Emits {SetTokenUri}
    /// and {TokenRevealed} if it is revealed in the process.
    /// @param tokenId the id of the token to override these things for
    /// @param overrideBaseURI whether the base URI should be overridden or `_tokenURI` should be
    /// appended to it
    /// @param overrideReveal whether the token should be individually revealed
    /// @param _tokenURI the new token URI
    function setTokenURI(
        uint256 tokenId,
        bool overrideBaseURI,
        bool overrideReveal,
        string memory _tokenURI
    ) external;

    /// @notice Sets the unrevealed token uri. Emits {UnrevealedTokenUriSet}.
    /// @param unrevealedTokenURI the new unrevealed token URI
    function setUnrevealedTokenURI(string memory unrevealedTokenURI) external;

    /// @notice Sets the base URI. Emits {SetBaseURI}.
    /// @param baseURI the new base uri
    function setBaseURI(string memory baseURI) external;

    /// @notice Returns whether the token `tokenId` overrides the full base URI.
    /// @param tokenId the id of the token to check
    /// @return overridesBaseURI whether the token overrides the full base URI
    function overridesFullURI(uint256 tokenId)
        external
        view
        returns (bool overridesBaseURI);

    /// @notice Returns whether the token `tokenId` is revealed.
    /// @param tokenId the id of the token to check
    /// @return revealed whether the token is revealed
    function tokenRevealed(uint256 tokenId)
        external
        view
        returns (bool revealed);
}