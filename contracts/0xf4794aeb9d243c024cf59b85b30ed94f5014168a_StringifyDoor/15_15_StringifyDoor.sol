// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @author: doorman

/*                                                                                                       
¨¨|||¨||¨||¨|¨¨|||¨|||¨¨¨¨|¨¨¨¨¨¨|||¨|¨¨|¨|¨|¨¨¨¨|¨¨|¨¨||¨¨¨|¨¨||¨|¨|¨||¨¨|
|                                                                         ¨
¨  ¨ ¨¨¨¨|¨¨¨¨¨¨|¨¨|¨||¨||¨||¨¨¨¨|¨||¨|||¨¨¨¨¨¨||||¨||¨¨¨¨||¨¨¨||||¨¨| |  ¨
|  |¨| ||¨¨¨|¨¨¨||||||¨¨||¨¨¨¨¨¨||¨|¨¨|¨|¨|¨¨¨|¨|||¨||¨|¨||¨|||¨||¨¨ |¨¨  |
|  |¨¨|¨ ¨||||¨|¨¨¨¨||¨¨¨¨¨¨¨||¨|||¨¨||¨||¨||¨|¨¨|||||¨¨|¨|¨¨|¨¨¨| ¨||¨|  |
|  ¨||¨||¨ ¨¨¨¨||||¨||||||¨|¨|¨|¨|¨||¨|||¨||||¨¨¨¨||¨|||||¨¨|||| ||¨||¨¨  ¨
|  |¨|¨|¨||| ¨||||||||||¨||¨¨¨¨¨|¨¨¨¨||||||¨¨¨|¨¨||¨|¨|||¨¨¨|| ||¨|||||¨  |
¨  ||¨|||¨||¨¨ ¨||¨¨|¨|¨¨||¨¨¨|¨¨|¨¨¨|¨¨|¨¨|¨|||¨¨|¨¨|¨|||¨| |¨¨|¨¨¨¨|¨|  ¨
¨  ¨||¨||¨|¨|¨|¨ ||¨|¨¨||¨¨¨||¨¨||¨¨||||¨¨|¨¨||¨¨¨||¨|¨¨¨| ¨|¨|¨||¨¨¨|¨¨  |
¨  ||¨¨¨¨¨¨¨¨¨|¨¨¨ ¨||¨|¨|¨¨|¨|¨¨|¨¨|¨|||¨¨¨|||||¨|¨||¨¨ |¨¨¨|¨||¨|¨||||  |
|  ||||¨¨|¨¨|¨|||¨|¨ ¨||¨|¨¨|||¨¨|¨¨¨|¨||¨¨¨¨¨|||||||| ||||||¨|¨¨¨¨||¨|¨  ¨
¨  |¨|¨|¨¨¨¨¨|¨¨|¨¨¨|| |¨¨|¨¨¨¨¨||¨||¨¨¨|||||||¨¨||| |¨|¨¨¨¨¨|¨¨||¨¨||||  |
¨  ¨|||¨¨|¨|¨||||¨¨|||¨¨ ||||||||¨|||¨¨¨¨¨¨||¨¨||¨ ||¨||¨¨||¨¨¨¨¨|||¨¨|¨  ¨
|  |¨|||||||||¨|¨|¨|¨||||¨ ¨¨||¨||¨|¨|¨¨¨¨||||¨| ¨¨||||||¨|¨¨¨||¨|¨|¨|||  ¨
¨  ||¨¨¨||¨¨|¨||||¨|¨¨|¨¨¨|¨ ¨¨¨¨|¨¨¨¨¨|||||¨¨ ¨||¨||¨||¨|||¨¨|¨|¨¨¨¨|¨|  ¨
|  |¨|¨|¨|¨¨¨|¨¨¨|||¨||¨|¨|¨¨|               |¨¨¨||||¨||¨|¨||¨¨¨||¨¨¨¨|¨  ¨
|  ¨¨||||||¨¨¨¨||¨¨¨||¨¨||¨¨|| ||¨¨|¨||||¨|| |¨||¨|¨¨|¨¨|||¨¨¨¨|||¨|¨¨¨¨  ¨
|  ||¨¨¨|¨¨¨||¨|¨¨¨||¨|¨|¨¨|¨¨ ¨           | ||¨|¨¨¨¨¨¨|||¨¨¨¨¨|¨||¨¨¨|¨  |
|  ¨¨¨¨¨|¨|¨¨¨¨||||¨||¨¨¨¨¨||| |           | ¨|¨¨¨¨¨|¨||¨¨¨|¨||¨¨¨¨¨|||¨  |
|  ||¨¨|||¨|¨¨¨¨||¨¨||¨||¨||¨| ¨           ¨ |¨||¨|||¨¨|||¨¨¨¨|¨|¨¨|||¨¨  |
¨  |¨|¨|¨¨|¨||¨|¨¨||¨¨¨|¨||¨|| ¨           | ¨¨¨|¨¨|||¨¨||¨¨|||||||¨¨|||  |
|  ||¨¨¨¨|¨¨|¨¨¨||¨||||||||¨¨| ¨           | ¨¨¨||||||¨|¨||¨¨||¨¨¨¨|¨||¨  |
|  ¨¨¨|¨¨|||¨¨|¨||||¨||¨||¨|¨¨ | ¨¨        | |||¨||||||||¨|¨||¨|¨||¨||¨|  ¨
¨  ¨|¨|¨¨¨|¨||¨|||||¨¨|¨||¨|¨| ¨           ¨ ¨¨|¨|¨|¨|¨¨|||||¨||||||¨¨|¨  ¨
¨  |¨||¨¨¨¨¨|¨||||¨¨¨¨¨¨||||¨¨ |           ¨ ¨¨¨¨¨¨¨|||¨|¨¨¨||||¨|¨¨||¨|  ¨
|  ¨¨|¨|¨¨¨|¨¨¨¨¨¨|¨¨¨|¨¨¨|||| ¨           ¨ |¨||¨||¨|¨¨||¨|¨¨¨||¨|¨¨¨¨¨  |
|  ||¨¨¨¨¨||¨|¨||¨|¨||¨|¨||¨¨| ¨           ¨ |¨|¨|||¨||¨¨|||¨||¨¨|¨|¨|||  ¨
|  ¨||¨¨¨|¨|¨¨¨¨|¨||||¨¨¨¨¨¨|¨ ¨           ¨ |¨¨¨||¨¨¨¨¨|¨||¨¨|¨||¨¨||¨|  |
¨  ¨||||||¨¨||¨||¨|¨||¨|¨|¨||| ¨||¨¨¨¨¨||¨¨¨ |||¨|¨|||||¨¨¨¨|¨||¨¨¨||¨|¨  |
|  ¨|¨¨|¨|||||¨¨¨¨¨|¨|¨|||||||               |¨¨¨|||||¨¨|¨¨¨||¨¨¨¨¨||¨|¨  |
|  ¨|||¨¨¨||¨¨¨¨||¨||¨|¨||¨¨ ¨||¨¨¨¨|¨||¨¨¨|¨¨ ||||||¨¨|¨¨|¨¨|¨¨¨¨¨¨|¨||  |
¨  ¨¨||¨|¨¨¨¨||||¨¨|||¨||¨ ||¨||¨|||||||||¨¨||¨| ¨|¨||||¨¨¨¨¨¨¨||¨||||¨|  |
¨  |||||¨||¨¨¨||¨||||¨|| |¨|¨|¨|¨|¨¨¨¨¨|¨¨|¨|¨||¨| |¨¨|¨||¨¨¨¨|||¨|¨|||¨  |
¨  |¨|¨||||¨|||¨¨¨¨||| |¨|¨¨|¨¨||||¨¨|¨¨||||||¨|||¨| ¨|¨¨|¨|¨|¨||||¨¨|||  |
|  ¨|¨¨¨||¨||¨¨|¨¨¨¨ ¨||¨|||¨||||||||¨¨¨|||¨|¨||¨|¨||¨ |¨||¨¨|¨¨||¨|¨¨||  |
¨  ¨¨¨¨¨|¨¨¨|||¨|¨ ¨||||¨|||¨¨¨||¨¨¨¨¨¨¨¨|¨¨|||¨¨|¨¨|||¨ |¨¨|¨¨|||¨|||¨|  |
¨  ¨|¨||||||¨||¨ |||||¨|¨¨¨¨¨|¨|¨¨¨¨¨¨¨||¨|¨¨¨¨¨|||¨||¨|¨¨ ¨|¨¨|¨|¨¨|¨||  |
¨  ¨¨||¨||¨¨|¨ ¨|¨||||¨¨¨¨¨¨¨|||||¨¨¨|||¨¨|||¨|¨|||¨||¨¨¨||| |¨¨||¨||¨|¨  |
¨  ¨¨|||¨¨|¨ ¨¨|||||||¨¨||¨|¨¨||¨¨¨¨||¨|||||||¨|¨¨|¨|¨¨¨¨|||¨¨ ¨¨|||¨||¨  ¨
¨  ¨|¨¨||| |||||¨¨¨|¨¨||¨¨¨||¨¨¨||¨¨¨|¨¨|||¨¨|||¨|¨¨||¨|||¨¨||¨| ¨|||¨¨¨  |
¨  ¨|¨¨| ¨¨|¨¨||¨¨¨¨|||¨¨|¨|¨||¨¨||¨¨|¨¨|¨|||¨¨||¨¨¨¨¨¨||¨¨|¨||||| ¨¨|||  |
|  ||¨ ¨¨|||||¨|||¨¨||¨¨¨¨¨¨||¨¨||¨|¨|||¨¨|||||||¨|¨|¨¨¨¨||¨||¨||¨¨| ¨¨|  |
|  ¨ ||¨¨|¨¨|¨|||¨¨¨¨¨¨|¨¨¨|¨¨¨¨¨¨||¨¨||||¨¨¨|¨¨¨|¨¨|¨|¨|¨¨|||¨|¨¨|¨|| ¨  |
¨                                                                         ¨
|¨¨¨||¨|¨|||||¨||¨||||¨¨¨¨¨|¨|¨|||¨|¨¨|¨|¨|¨¨¨¨¨¨||¨|||¨¨¨¨¨¨¨||¨¨|¨¨|¨¨|¨¨                                   
*/                                                                                                                                                                                                                   

contract StringifyDoor is ERC721Enumerable, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    struct PrivateKeys {
        address earlyInsider;
        address regularInsider;
        address lateInsider;
    }

    PrivateKeys private privateKeys;

    uint256 public maxSupply = 10000;

    bool public theDoorIsOpen = false;
    bool public presaleMintIsActive = false;
    bool public mintIsActive = false;

    uint256 public constant MINT_PRICE = 20000000000000000; // 0.02 ETH

    string[3] private lastPuzzlePieces;
    string[] private symbolsLibrary = [
        '!', '&quot;', '#', '$', '%', '&amp;', '(', ')', '*', '+', '-', '/', ':', '0', 'O', 'o', 
        ';', '=', '&lt;', '&gt;', '?', '@', '[', ']', '^', '_', '`', '{', '|', '}', '~', 'V',
        '\x27', '\xc2\xa1', '\xc2\xa2', '\xc2\xa4', '\xc2\xa6', '\xc2\xa7', '\xc2\xa8', '\xc2\xaa', '\xe2\x95\xa6', '\xe2\x95\xa0',
        // '         ¡           ¢           ¤            ¦           §           ¨          ª             ╦            ╠
        '\xc2\xab', '\xc2\xac',  '\xc2\xaf', '\xc2\xb2', '\xc2\xb3', '\xc2\xb4', '\xc2\xb6', '\xc2\xb7', '\xc2\xb8', '\xc2\xb9',
        //   «           ¬           ¯           ²           ³           ´           ¶           ·           ¸           ¹    
        '\xc2\xba', '\xc2\xbb', '\xc2\xbf', '\xe2\x94\x82', '\xe2\x94\xa4', '\xe2\x97\x88', '\xe2\x94\x94', '\xe2\x95\xa9',
        //   º           »           ¿             │              ┤               ◈               └               ╩
         '\xc3\x97', '\xc3\x98', '\xc3\x9e', '\xe2\x95\xa3', '\xe2\x95\x91', '\xe2\x95\x97', '\xe2\x95\x9d', '\xe2\x94\x90',
        //   ×           Ø           Þ             ╣                ║               ╗                ╝              ┐               
        '\xc3\x9f', '\xe2\x94\xb4', '\xe2\x94\xac', '\xe2\x94\x9c', '\xe2\x94\x80', '\xe2\x94\xbc', '\xe2\x95\x9a', '\xe2\x95\x94',
        //   ß           ┴                ┬                ├               ─               ┼               ╚               ╔               
        '\xc6\x92', '\xe2\x80\x93', '\xe2\x80\x94', '\xe2\x80\x98', '\xe2\x80\x99', '\xe2\x80\x9a', '\xe2\x80\x9c', '\xe2\x80\x9d',
        //   ƒ             –               —               ‘               ’               ‚               “               ”
        '\xe2\x80\x9e', '\xe2\x80\xa0', '\xe2\x80\xa1', '\xe2\x80\xa2', '\xe2\x80\xa6', '\xe2\x95\x90', '\xe2\x95\xac', '\xe2\x94\x98',
        //     „              †               ‡                •               …              ═               ╬               ┘
        '\xe2\x94\x8c', '\xe2\x89\xa1', '\xe2\x80\x97', '\xe2\x99\xa6', '\xe2\x9c\x95', '\xe2\x97\x8e', '\xc3\x90'];
        //   ┌                ≡               ‗              ♦                 ✕              ◎              Ð

    function draw (uint256 tokenId, uint8 tokenType, string[3] memory symbols) internal pure returns (string memory) {
        string[2] memory colors = ['white', 'black'];
        string memory drawing;
        string memory symbol;
        string memory line;
        
        if (tokenType == 1) {
            colors[0] = 'black';
            colors[1] = 'white';
        }

        /* Draw instructions */
        for (uint256 y = 0; y < 45; y++) {
            line = '<tspan x="25" dy="10">';
            for (uint256 x = 0; x < 75; x++) {
                if (((y == 1 || y == 43) && x > 1 && x < 74) || 
                    ((x == 1 || x == 2 || x == 73 || x == 72 ) && (y > 0 && y < 44)) || 
                    ((y != 22 && y > 16 && y < 28 && x > 31 && x < 43)) || 
                    (y == 22 && x > 31 && x < 43 && x != 33 && x != 34) ||
                    ((y == 15 || y == 29) && x > 29 && x < 45) ||
                    ((x == 30|| x == 44) && y > 15 && y < 29) ||
                    (y > 1 && y < 15 && (x == y * 2 || x == 74 - y * 2)) ||
                    (y > 29 && y < 43 && ((x == y * 2 - 14) || (x == 88 - y * 2)))) {
                    line = string(abi.encodePacked(line, ' '));
                } else {
                    symbol = symbols[0];
                    uint randomNumber = random(string(abi.encodePacked(toString(y), toString(x), toString(tokenId)))) % 300;
                    if (randomNumber > 99 && randomNumber < 200) {
                        symbol = symbols[1];
                    } else if (randomNumber > 199) {
                        symbol = symbols[2];
                    }
                    line = string(abi.encodePacked(line, symbol));
                }
            }
            drawing = string(abi.encodePacked(drawing, line, '</tspan>'));
        }

        drawing = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" height="500" width="500">',
                '<rect width="500" height="500" x="0" y="0" style="fill:',
                colors[1],
                ';" /><text x="25" y="25" style="fill:',
                colors[0],
                ';font-family: courier;font-size:10px;" xml:space="preserve">', 
                drawing, 
                '</text></svg>'
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(drawing))));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!theDoorIsOpen) {
            /* Return the placeholder before the reveal */
            string memory closedDoorOutput = Base64.encode(bytes(abi.encodePacked('{"name": "Door #', toString(tokenId) ,' (unrevealed)", "description": "Be patient.", "image": "https://door.stringify.art/placeholder.gif"}')));
            return string(abi.encodePacked("data:application/json;base64,", closedDoorOutput));
        } 

        uint8 tokenType = 0;
        string memory background = 'black';
        string[2] memory json;
        string[3] memory symbols = [
            symbolsLibrary[random(string(abi.encodePacked(lastPuzzlePieces[0], toString(tokenId)))) % symbolsLibrary.length], 
            symbolsLibrary[random(string(abi.encodePacked(lastPuzzlePieces[1], toString(tokenId)))) % symbolsLibrary.length],
            symbolsLibrary[random(string(abi.encodePacked(lastPuzzlePieces[2], toString(tokenId)))) % symbolsLibrary.length]
        ];

        /* White background color */
        if ((random(string(abi.encodePacked(toString(tokenId)))) % 100) < 1) {
            tokenType = 1;
            background = 'white';
        }

        string memory output = draw(tokenId, tokenType, symbols);

        json[0] = string(
            abi.encodePacked(
                '{"name": "Door #',
                toString(tokenId),
                '", "id": "',
                toString(tokenId),
                '", "description": "Stringify(door) is a collection of 10k minimalist doors randomly generated by the Ethereum blockchain and stored in it forever.", "image": "'
            )
        );

        json[1] = string(
            abi.encodePacked(
                output,
                '", "attributes":[{"trait_type":"First symbol","value":"',
                symbols[0],
                '"}, {"trait_type":"Second symbol","value":"',
                symbols[1],
                '"}, {"trait_type":"Third symbol","value":"',
                symbols[2],
                '"}, {"trait_type":"Symbols triplet","value":"',
                string(abi.encodePacked(symbols[0], symbols[1], symbols[2])),
                '"}, {"trait_type":"Background","value":"',
                background,
                '"}]}'
            )
        );

        string memory result = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        json[0],
                        json[1]
                    )
                )
            )
        );

        output = string(abi.encodePacked("data:application/json;base64,", result));

        return output;
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant  {
        require(mintIsActive, "Public mint is not active at the moment. Be patient.");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0.");
        require(totalSupply() + numberOfTokens <= maxSupply, "Purchase would exceed max supply.");
        require(numberOfTokens <= 4, "Can only mint up to 4 per transaction.");
        require(MINT_PRICE * numberOfTokens == msg.value, "Sent ETH value is incorrect.");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    function presaleMint(uint256 numberOfTokens, bytes memory signature) public payable nonReentrant  {
        require(presaleMintIsActive, "Presale mint is not active at the moment. Be patient.");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0.");
        require(totalSupply() + numberOfTokens <= maxSupply, "Purchase would exceed max supply.");

        // Verify EIP-712 signature
        address recoveredKey = keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(signature);
        require(recoveredKey == privateKeys.earlyInsider || recoveredKey == privateKeys.regularInsider || recoveredKey == privateKeys.lateInsider, "Your wallet is not whitelisted for the presale.");

        // Verify nb of tokens in wallet
        if (recoveredKey == privateKeys.earlyInsider) {
            require(balanceOf(msg.sender) + numberOfTokens <= 3, "Can only mint up to 3 per wallet.");
        } else if (recoveredKey == privateKeys.regularInsider) {
            require(balanceOf(msg.sender) + numberOfTokens <= 2, "Can only mint up to 2 per wallet.");
        } else if (recoveredKey == privateKeys.lateInsider) {
            require(balanceOf(msg.sender) + numberOfTokens == 1, "Can only mint up to 1 per wallet.");
        }

        require(MINT_PRICE * numberOfTokens == msg.value, "Sent ETH value is incorrect.");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), totalSupply() + 1);
        }
    }

    function setPrivateKeys(address[3] memory keys) public onlyOwner {
        privateKeys = PrivateKeys(keys[0], keys[1], keys[2]);
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipPresaleMintState() public onlyOwner {
        presaleMintIsActive = !presaleMintIsActive;
    }

    function openTheDoor (string[3] memory _lastPuzzlePieces) public onlyOwner {
        require(!theDoorIsOpen, "The door can be opened only once.");
        lastPuzzlePieces = _lastPuzzlePieces;
        theDoorIsOpen = true;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function random(string memory input) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("Stringify(door)", "S") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}