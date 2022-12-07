// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./TypeVVriter.sol";

/**
         █
         █
         █
 ▄       █                             █
 █       █       ▄         ▃ █         █
 █       █     █ █         █ █     ▆ █ █
 █     ▄ █     █ █     ▃   █ █     █ █ █
 █   ▂ █ █     █ █     █   █ █     █ █ █ ▃
 █ ▂ █ █ █ █ ▆ █ █     █ █ █ █ ▆   █ █ █ █   █   ▆
 █ █ █ █ █ █ █ █ █ ▂ ▆ █ █ █ █ █ ▂ █ █ █ █ ▇ █ ▂ █ ▁
-----------------------------------------------------
 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
-----------------------------------------------------
  _______ _____   ___  ___  __________________  ____
 / ___/ // / _ | / _ \/ _ |/ ___/_  __/ __/ _ \/ __/
/ /__/ _  / __ |/ , _/ __ / /__  / / / _// , _/\ \
\___/_//_/_/ |_/_/|_/_/ |_\___/ /_/ /___/_/|_/___/

=====================================================
@title  CHRCTRS
@author VisualizeValue
@notice Everything is a derivative of this.
*/
contract Characters is ERC721 {
    /// @notice Our general purpose TypeVVriter. Write with Characters on chain.
    TypeVVriter public typeVVriter;

    /// @notice The 26 base characters of the modern Latin alphabet.
    string[26] public CHARACTERS = [
        "A", "B", "C", "D", "E", "F", "G",
        "H", "I", "J", "K", "L", "M", "N",
        "O", "P", "Q", "R", "S", "T", "U",
        "V", "W", "X", "Y", "Z"
    ];

    /// @notice The rarities of characters in the Concise Oxford Dictionary.
    /// Samuel Morse used these to assign the simplest keys
    /// to the most common letters in Morse code.
    string[26] public CHARACTER_RARITIES = [
        "8.4966", "2.0720", "4.5388", "3.3844", "11.1607", "1.8121", "2.4705",
        "3.0034", "7.5448", "0.1965", "1.1016", "5.4893", "3.0129", "6.6544",
        "7.1635", "3.1671", "0.1962", "7.5809", "5.7351", "6.9509", "3.6308",
        "1.0074", "1.2899", "0.2902", "1.7779", "0.2722"
    ];

    /// @dev Create the new Characters collection.
    constructor() ERC721("Characters", "CHRCTRS") {
        // Deploy the TypeVVriter
        typeVVriter = new TypeVVriter(_msgSender());

        // Mint all character tokens
        for (uint256 id = 1; id <= CHARACTERS.length; id++) {
            _mint(address(this), id);
        }
    }

    /// @notice Get the Metadata for a given Character ID.
    /// @dev The token URI for a given character.
    /// @param tokenId The character ID to show.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory character = CHARACTERS[tokenId - 1];
        string memory letter = typeVVriter.LETTERS(character);
        string memory rarity = CHARACTER_RARITIES[tokenId - 1];

        uint256 characterWidth = typeVVriter.LETTER_WIDTHS(character) > 0
            ? typeVVriter.LETTER_WIDTHS(character)
            : typeVVriter.LETTER_WIDTHS("DEFAULT");
        uint256 center = 285;
        uint256 em = 30;

        string memory left = Strings.toString(center - characterWidth);
        string memory top = Strings.toString(center - em);

        string memory svg = string(abi.encodePacked(
            '<svg ',
                'viewBox="0 0 570 570" width="1400" height="1400" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg"',
            '>',
                '<rect width="570" height="570" fill="black"/>',
                '<path transform="translate(', left, ',', top, ') ',
                    'scale(2)" d="', letter, '" fill="white"',
                '/>'
            '</svg>'
        ));

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "', character, '",',
                '"description": "Rarity: ', rarity, '%",',
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @notice Number of characters in the modern Latin alphabet.
    /// @dev Returns the total amount of tokens stored by the contract.
    function totalSupply() external pure returns (uint256) {
        return 26;
    }

    /// @dev Hook for `saveTransferFrom` of ERC721 tokens to this contract.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the token being transferred.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public returns (bytes4) {
        require(
            msg.sender == 0x6600a2c1dcb2ffA98a6D71F4Bf9e5b34173E6D36,
            "Only accepting deposits from the old Character collection"
        );

        uint256 id = 27 - tokenId;

        _transfer(address(this), from, id);

        return IERC721Receiver.onERC721Received.selector;
    }
}