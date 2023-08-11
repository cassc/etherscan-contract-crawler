// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'base64-sol/base64.sol';

/**
 * @title TheColors contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TheColors is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint32;

    string public PROVENANCE_HASH = "";

    uint256 public constant colorPrice = 0.06 ether; //0.06 ETH

    uint public constant maxColorPurchase = 20;

    uint256 public MAX_COLORS;

    bool public saleIsActive = false;

    mapping(uint256 => uint32) private _hexColors;
    mapping(uint32 => bool) public existingHexColors;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply) ERC721(name, symbol) {
        MAX_COLORS = maxNftSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_hexColors[tokenId] > 0, "ERC721Metadata: URI query for nonexistent token");

        uint32 hexColor = _hexColors[tokenId];
        string memory hexString = uintToHexString(hexColor);
        string memory image = Base64.encode(bytes(generateSVGImage(hexString)));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"image":"',
                            'data:image/svg+xml;base64,',
                            image,
                            '",',
                            '"image_data":"',
                            escapeQuotes(generateSVGImage(hexString)),
                            '",',
                            generateNameDescription(tokenId, hexString),
                            generateAttributes(hexColor, hexString),
                            '}'
                        )
                    )
                )
            )
        );
    }

    function getTokenMetadata(uint256 tokenId) public view returns (string memory) {
        uint32 hexColor = _hexColors[tokenId];
        string memory hexString = uintToHexString(hexColor);
        string memory image = Base64.encode(bytes(generateSVGImage(hexString)));

        return string(
            abi.encodePacked(
                'data:application/json',
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                image,
                '",',
                '"image_data":"',
                escapeQuotes(generateSVGImage(hexString)),
                '",',
                generateNameDescription(tokenId, hexString),
                generateAttributes(hexColor, hexString),
                '}'
            )
        );
    }

    function getTokenSVG(uint256 tokenId) public view returns (string memory) {
        uint32 hexColor = _hexColors[tokenId];
        string memory hexString = uintToHexString(hexColor);
        return generateSVGImage(hexString);
    }

    function getBase64TokenSVG(uint256 tokenId) public view returns (string memory) {
        uint32 hexColor = _hexColors[tokenId];
        string memory hexString = uintToHexString(hexColor);
        string memory image = Base64.encode(bytes(generateSVGImage(hexString)));
        return string(
            abi.encodePacked(
                'data:application/json;base64',
                image
            )
        );
    }

    function getHexColor(uint256 tokenId) public view returns (string memory) {
        uint32 hexColor = _hexColors[tokenId];
        string memory hexString = uintToHexString(hexColor);
        return string(
            abi.encodePacked(
                '#',
                hexString
            )
        );
    }

    function getRGB(uint256 tokenId) public view returns (string memory) {
        string memory r = getRed(tokenId).toString();
        string memory g = getGreen(tokenId).toString();
        string memory b = getBlue(tokenId).toString();

        return string(abi.encodePacked('rgb(', r, ',', g, ',', b, ')'));
    }

    function getRed(uint256 tokenId) public view returns (uint32) {
        uint32 hexColor = _hexColors[tokenId];
        return ((hexColor >> 16) & 0xFF);  // Extract the RR byte
    }

    function getGreen(uint256 tokenId) public view returns (uint32) {
        uint32 hexColor = _hexColors[tokenId];
        return ((hexColor >> 8) & 0xFF);  // Extract the GG byte
    }

    function getBlue(uint256 tokenId) public view returns (uint32) {
        uint32 hexColor = _hexColors[tokenId];
        return ((hexColor) & 0xFF);  // Extract the BB byte
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE_HASH = provenanceHash;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints The Colors
    */
    function mintColor(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Color");
        require(numberOfTokens <= maxColorPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply() + numberOfTokens <= MAX_COLORS, "Purchase would exceed max supply of Colors");
        require(colorPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_COLORS) {
                _safeMint(msg.sender, mintIndex);
                generateTokenURI(mintIndex);
            }
        }
    }

    function generateTokenURI(uint256 tokenId) internal {
        uint32 hexColor = generateRandomHexColor();

        existingHexColors[hexColor] = true;
        _hexColors[tokenId] = hexColor; 
    }

    function generateNameDescription(uint256 tokenId, string memory hexString) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '"external_url":"https://thecolors.art",',
                unicode'"description":"The Colors are a set of 8,888 iconic shades generated and stored entirely on-chain to be used as a primitive and for color field vibes. ~ A Color is Forever ∞',
                '\\nHex: #',
                hexString,
                '\\n\\nToken id: #',
                tokenId.toString(),
                '",',
                '"name":"#',
                hexString,
                '",'
            )
        );
    }

    function generateAttributes(uint32 hexColor, string memory hexString) internal pure returns (string memory) {
        string memory r = ((hexColor >> 16) & 0xFF).toString();  // Extract the RR byte
        string memory g = ((hexColor >> 8) & 0xFF).toString();   // Extract the GG byte
        string memory b = ((hexColor) & 0xFF).toString();        // Extract the BB byte

        string memory rgb = string(abi.encodePacked('rgb(', r, ',', g, ',', b, ')'));

        return string(
            abi.encodePacked(
                '"attributes":[',
                '{"trait_type":"Hex code","value":"#',
                hexString,
                '"},'
                '{"trait_type":"RGB","value":"',
                rgb,
                '"},',
                '{"trait_type":"Red","value":"',
                r,
                '"},',
                '{"trait_type":"Green","value":"',
                g,
                '"},',
                '{"trait_type":"Blue","value":"',
                b,
                '"}',
                ']'
            )
        );
    }

    function generateSVGImage(string memory hexString) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg width="690" height="690" xmlns="http://www.w3.org/2000/svg" style="background-color:#',
                hexString,
                '">',
                '</svg>'
            )
        );
    }

    function generateRandomHexColor() internal returns (uint32) {
        uint32 hexColor = uint32(_rng() % 16777215);

        while (existingHexColors[hexColor]) {
          hexColor = (hexColor + 1) % 16777215;
        }

        return hexColor;
    }
    
    function uintToHexString(uint256 number) public pure returns(string memory) {
        bytes32 value = bytes32(number);
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(6);
        for (uint i = 0; i < 3; i++) {
            str[i*2] = alphabet[uint(uint8(value[i + 29] >> 4))];
            str[1+i*2] = alphabet[uint(uint8(value[i + 29] & 0x0f))];
        }
        
        return string(str);
    }

    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint quotesCount = 0;
        for (uint i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function _rng() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty))) +
                uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp + block.gaslimit +
                uint256(keccak256(abi.encodePacked(msg.sender))) / (block.timestamp + block.number);
    }
}