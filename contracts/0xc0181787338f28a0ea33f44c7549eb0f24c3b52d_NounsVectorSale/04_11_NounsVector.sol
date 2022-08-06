// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import "./lib/Base64.sol";

contract NounsVector is ERC721, Owned, AccessControl {
    // Artwork and edition # that a token corresponds to.
    struct TokenInfo {
        uint8 artwork;
        uint8 edition;
    }

    // Role that can change the image base URI.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Role that can mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Image base URI.
    string public imageBaseURI;

    // Total supply.
    uint256 public totalSupply;

    // Supply per artwork.
    mapping(uint256 => uint256) private artworkSupplies;

    // Artwork and edition info for a token.
    mapping(uint256 => TokenInfo) private tokenInfos;

    constructor(string memory _imageBaseURI) ERC721("Nouns x Vector", "NOUNV") Owned(msg.sender) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        imageBaseURI = _imageBaseURI;
    }

    // ADMIN //

    /**
     * @notice Change the base URI for the image.
     */
    function setImageBaseURI(string calldata _imageBaseURI) public onlyRole(ADMIN_ROLE) {
        imageBaseURI = _imageBaseURI;
    }

    // PUBLIC //

    /**
     * @notice Require that the sender is the minter.
     * @param _id The token ID.
     * @return string The token metadata encoded in base64.
     */
    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(_exists(_id), "ERC721Metadata: URI query for nonexistent token");

        TokenInfo memory tokenInfo = tokenInfos[_id];

        string memory base64JSON = Base64.encode(
            bytes(
                string.concat(
                    '{',
                        '"name": "', _getTokenName(tokenInfo.artwork, tokenInfo.edition), '", ',
                        '"description": "', _getArtworkDescription(tokenInfo.artwork), '", ',
                        '"image": "', imageBaseURI, Strings.toString(tokenInfo.artwork), '", ',
                        '"attributes": ', _getArtworkAttributes(tokenInfo.artwork, tokenInfo.edition),
                    '}'
                )
            )
        );

        return string.concat('data:application/json;base64,', base64JSON);
    }

    // EXTERNAL //

    /**
     * @notice Mints a token of an artwork to an account. Only the privileged
     *         minter role may mint tokens.
     * @param _to The recipient of the minting.
     * @param _artwork The artwork to mint.
     */
    function mint(
        address _to,
        uint256 _artwork
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(_to, totalSupply);

        unchecked {
            ++artworkSupplies[_artwork]; // 1-indexed
        }

        tokenInfos[totalSupply] = TokenInfo(uint8(_artwork), uint8(artworkSupplies[_artwork]));

        unchecked {
            ++totalSupply;
        }
    }

    /**
     * @notice Returns the number of tokens minted of an artwork.
     * @param _artwork The artwork in question.
     * @return Number of editions.
     */
    function artworkSupply(uint256 _artwork) external view returns (uint256) {
        return artworkSupplies[_artwork];
    }

    // INTERNAL //

    /**
     * @notice Returns the artist of the artwork.
     * @param _artwork The artwork in question.
     * @return Name of the artist.
     */
    function _getArtworkArtist(uint256 _artwork) internal pure returns (string memory) {
        if (_artwork == 0) {
            return "Adam Ho";
        } else if (_artwork == 1) {
            return "Elijah Anderson";
        } else if (_artwork == 2) {
            return "Eric Hu";
        } else if (_artwork == 3) {
            return "Haruko Hayakawa";
        } else if (_artwork == 4) {
            return "Lulu Lin";
        } else if (_artwork == 5) {
            return "Moon Collective";
        } else if (_artwork == 6) {
            return "Shawna X";
        } else {
            return "Yasly";
        }
    }

    /**
     * @notice Returns the name of the token for metadata.
     * @param _artwork The artwork in question.
     * @param _edition The edition number.
     * @return Name of the token.
     */
    function _getTokenName(uint256 _artwork, uint256 _edition) internal pure returns (string memory) {
        return string.concat(_getArtworkArtist(_artwork), " #", Strings.toString(_edition), " ", unicode"—", " Nouns x Vector");
    }

    /**
     * @notice Returns the description of the artwork.
     * @param _artwork The artwork in question.
     * @return Description of the artwork.
     */
    function _getArtworkDescription(uint256 _artwork) internal pure returns (string memory) {
        if (_artwork == 0) {
            return "Adam Ho is a designer and artist with a strong focus on branding, interaction design, and art direction. He is based in Queens, New York. He has worked with clients such as Medium, Airbnb, Square, Dropbox, Postmates, and Nike.";
        } else if (_artwork == 1) {
            return "Elijah Anderson is a multidisciplinary artist who has collaborated and worked with a range of brands and publications including New York Mag, Popeye mag, Adidas, Sneakers n Stuff, and Bookworks. He currently lives in Brooklyn, New York.";
        } else if (_artwork == 2) {
            return "Eric Hu is an independent creative director and typographer. Through the visual identity work of his eponymous design studio, his art direction for Mold Magazine, previous tenures leading design at Nike and SSENSE, Hu has been influential in shaping the visual language of some of the most lasting cultural, commercial, and institutional voices of the past decade.";
        } else if (_artwork == 3) {
            return "Haruko Hayakawa is a CG Artist and Creative Director based in Brooklyn, New York. Her work focuses on her Japanese-American culture, materiality and form. She has worked with The New York Times, Bon Appetit, Fly by Jing, Panera Bread and SKYY Vodka.";
        } else if (_artwork == 4) {
            return "Lulu Lin is an interdisciplinary designer, she has garnered the most public interest for her illustrations. Her drawings has been described as subverting human forms in surprising and engrossing ways, often lumpy and fleshy, strike the viewer as playful, surreal, and sometimes unsettling.";
        } else if (_artwork == 5) {
            return "Moon Collective is an Asian American clothing and design studio based in the Bay Area and Honolulu. We draw inspiration from minimalism, a peaceful journey, funny memories and psychedelic folklore. We produce designs we love throughout the four seasons and dedicate our time developing our in-house brand, Moon strives to build community through our work and our friendship.";
        } else if (_artwork == 6) {
            return "Shawna X an artist based in New York City, known for her vibrant and surreal image-making on projects about identity, motherhood, and community. Her recent collaborations include public art takeovers with large-scale murals in Brazil, and NYC LIRR station debuting in fall of 2022.";
        } else {
            return string.concat(
                "YASLY is Danny Jones, a 3D Designer living in San Francisco, California exploring the space between what is real and what is not",
                unicode"—",
                "3D helps him understand and see in a new way. Danny's constantly taking notice of the imperfections in the world and how those translate into the work he creates."
            );
        }
    }

    /**
     * @notice Returns the attributes of the artwork.
     * @param _artwork The artwork in question.
     * @param _edition The edition of the artwork.
     * @return Attributes describing the token.
     */
    function _getArtworkAttributes(uint256 _artwork, uint256 _edition) internal pure returns (string memory) {
        return string.concat(
            '[',
                '{"trait_type": "artist", "value": "', _getArtworkArtist(_artwork), '"},',
                '{"trait_type": "edition", "value": "', Strings.toString(_edition), '"},',
                '{"trait_type": "license", "value": "CC BY-NC-SA 4.0"}',
            ']'
        );
    }

    /**
     * @notice Returns whether a token has been minted or not.
     * @param _id The token ID.
     * @return Whether it exists or not.
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return _ownerOf[_id] != address(0);
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IAccessControl).interfaceId;
    }
}